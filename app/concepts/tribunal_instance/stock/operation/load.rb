module TribunalInstance
  module Stock
    module Operation
      class Load < Trailblazer::Operation
        extend ClassDependencies
        include TrailblazerHelper::DBIndexes

        self[:stocks_folder] = ::File.join(Rails.configuration.rncs_sources_path, 'titmc', 'stock')
        self[:stock_class] = StockTribunalInstance

        pass ->(ctx, logger:, **) { logger.info 'Checking last TITMC stock...' }
        step Subprocess(RetrieveLastStock), Output(:failure) => Id(:log_sub_operation_failure)
        pass :log_current_stock
        step ->(ctx, stock:, **) { stock.newer? }
          fail :log_not_newer_stock, fail_fast: true
        step ->(ctx, stock:, **) { stock.save }
        step Subprocess(PrepareImport), Output(:fail_fast) => Track(:failure)
          fail :log_sub_operation_failure
        step :drop_db_index
        step :import

        def drop_db_index(ctx, **)
          drop_queries(:tribunal_instance).each { |query| ActiveRecord::Base.connection.execute(query) }
        end

        def import(ctx, stock_units:, **)
          stock_units.each do |stock_unit|
            ImportTitmcStockUnitJob.perform_later(stock_unit.id)
          end
        end

        def log_current_stock(ctx, logger:, stock:, **)
          logger.info "Current #{stock.type}: #{stock.date}"
        end

        def log_not_newer_stock(ctx, logger:, **)
          current_stock = StockTribunalInstance.current
          logger.error "No stock newer than #{current_stock.date} available ; current stock status: #{current_stock.status}"
        end

        def log_sub_operation_failure(ctx, logger:, error:, **)
          logger.error error
        end
      end
    end
  end
end
