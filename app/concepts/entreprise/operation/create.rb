class Entreprise
  module Operation
    class Create < Trailblazer::Operation
      step Model(Entreprise, :new)
      step Trailblazer::Operation::Contract::Build(constant: Entreprise::Contract::Create)
      step Trailblazer::Operation::Contract::Validate()
      step Trailblazer::Operation::Contract::Persist()
    end
  end
end