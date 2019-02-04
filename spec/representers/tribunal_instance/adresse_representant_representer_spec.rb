require 'rails_helper'

describe TribunalInstance::AdresseRepresentantRepresenter, :representer do
  subject do
    entreprise_pm_representer
      .representants
      .first
      .adresse_representant
  end

  it { is_expected.to be_a TribunalInstance::AdresseRepresentant }

  its(:residence)       { is_expected.to eq 'là bas' }
  its(:nom_voie)        { is_expected.to eq 'VOIX' }
  its(:code_postal)     { is_expected.to eq '75000 et BUREAU' }
  its(:localite)        { is_expected.to eq 'BANANA' }
  its(:pays)            { is_expected.to eq 'NO COUNTRY FOR OLD MEN' }
end
