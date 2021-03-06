require 'rails_helper'

describe TribunalCommerce::PartialStockUnit::Operation::Load, :trb do
  let(:logger) { instance_spy(Logger) }
  let(:unit) { create(:daily_update_unit, files_path: fixtures_path) }

  # This fixture archive contains the following files :
  # - 0384_S2_20180409_1_PM.csv
  # - 0384_S2_20180409_3_PP.csv
  # - 0384_S2_20180409_5_rep.csv
  # - 0384_S2_20180409_8_ets.csv
  # - 0384_S2_20180409_11_obs.csv
  # - 0384_S2_20180409_12_actes.csv
  # - 0384_S2_20180409_13_comptes_annuels.csv
  let(:fixtures_path) { Rails.root.join('spec/fixtures/tc/partial_stock/2018/04/09/0384_S2_20180409.zip') }

  # Testing unit tests here so we mock the file importer dependency
  let(:file_importer) do
    dbl = instance_spy(TribunalCommerce::Helper::FileImporter)
    dbl
  end

  subject { described_class.call(daily_update_unit: unit, logger: logger, file_importer: file_importer) }

  after do
    # Clean unit extraction directory
    FileUtils.rm_rf(Rails.root.join('tmp/0384_S2_20180409'))
  end

  it 'logs that the import starts' do
    subject

    expect(logger)
      .to have_received(:info)
      .with('Starting import of partial stock unit...')
  end

  describe 'unit archive extraction' do
    it 'calls ZIP::Operation::Extract' do
      expect_to_call_nested_operation(ZIP::Operation::Extract)

      subject
    end

    it 'fetches all the files inside unit archive' do
      unit_files = subject[:extracted_files]

      expect(unit_files).to contain_exactly(
        a_string_ending_with('tmp/0384_S2_20180409/0384_S2_20180409_1_PM.csv'),
        a_string_ending_with('tmp/0384_S2_20180409/0384_S2_20180409_3_PP.csv'),
        a_string_ending_with('tmp/0384_S2_20180409/0384_S2_20180409_5_rep.csv'),
        a_string_ending_with('tmp/0384_S2_20180409/0384_S2_20180409_8_ets.csv'),
        a_string_ending_with('tmp/0384_S2_20180409/0384_S2_20180409_11_obs.csv'),
        a_string_ending_with('tmp/0384_S2_20180409/0384_S2_20180409_12_actes.csv'),
        a_string_ending_with('tmp/0384_S2_20180409/0384_S2_20180409_13_comptes_annuels.csv'),
      )
    end

    context 'with an invalid archive' do
      let(:fixtures_path) { Rails.root.join('spec/fixtures/tc/falsey_stocks/unexpected_filename.zip') }

      it { is_expected.to be_failure }

      it 'logs the error' do
        subject

        expect(logger).to have_received(:error)
          .with("An error happened while trying to extract unit archive #{unit.files_path} : #{subject[:error]}")
      end
    end
  end

  describe 'filename deserialization' do
    it 'creates a hash of data from filenames' do
      data = subject[:files_args]

      expect(data).to contain_exactly(
        a_hash_including(code_greffe: '0384', label: 'PM', path: a_string_ending_with('0384_S2_20180409_1_PM.csv')),
        a_hash_including(code_greffe: '0384', label: 'PP', path: a_string_ending_with('0384_S2_20180409_3_PP.csv')),
        a_hash_including(code_greffe: '0384', label: 'rep', path: a_string_ending_with('0384_S2_20180409_5_rep.csv')),
        a_hash_including(code_greffe: '0384', label: 'ets', path: a_string_ending_with('0384_S2_20180409_8_ets.csv')),
        a_hash_including(code_greffe: '0384', label: 'obs', path: a_string_ending_with('0384_S2_20180409_11_obs.csv')),
        a_hash_including(code_greffe: '0384', label: 'actes', path: a_string_ending_with('0384_S2_20180409_12_actes.csv')),
        a_hash_including(code_greffe: '0384', label: 'comptes_annuels', path: a_string_ending_with('0384_S2_20180409_13_comptes_annuels.csv')),
      )
    end

    context 'when filenames are invalid' do
      before do
        allow_any_instance_of(TribunalCommerce::Helper::DataFile)
          .to receive(:parse_stock_filename)
          .and_raise(TribunalCommerce::Helper::DataFile::UnexpectedFilename, 'much error')
      end

      it { is_expected.to be_failure }

      it 'logs the error' do
        subject

        expect(logger).to have_received(:error)
          .with('An error occured while parsing unit\'s files : much error')
      end
    end
  end

  describe 'unit\'s files import' do
    it 'imports data files in the right order' do
      subject

      expect_ordered_import_call(:supersede_dossiers_entreprise_from_pm, '0384_S2_20180409_1_PM.csv')
      expect_ordered_import_call(:import_personnes_morales, '0384_S2_20180409_1_PM.csv')
      expect_ordered_import_call(:supersede_dossiers_entreprise_from_pp, '0384_S2_20180409_3_PP.csv')
      expect_ordered_import_call(:import_personnes_physiques, '0384_S2_20180409_3_PP.csv')
      expect_ordered_import_call(:import_representants, '0384_S2_20180409_5_rep.csv')
      expect_ordered_import_call(:import_etablissements, '0384_S2_20180409_8_ets.csv')
      expect_ordered_import_call(:import_observations, '0384_S2_20180409_11_obs.csv')
    end

    context 'when a file\'s import fails' do
      before { allow(file_importer).to receive(:supersede_dossiers_entreprise_from_pp).and_return(false) }

      subject { described_class.call(daily_update_unit: unit, logger: logger, file_importer: file_importer) }

      it { is_expected.to be_failure }

      it 'does not import the following files' do
        subject

        expect(file_importer).to_not have_received(:import_personnes_physiques)
        expect(file_importer).to_not have_received(:import_representants)
        expect(file_importer).to_not have_received(:import_etablissements)
        expect(file_importer).to_not have_received(:import_observations)
      end
    end

    def expect_ordered_import_call(import_name, file_path)
      expect(file_importer).to have_received(import_name)
        .with(a_string_ending_with(file_path))
        .ordered
    end
  end
end
