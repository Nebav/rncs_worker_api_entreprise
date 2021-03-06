FactoryBot.define do
  factory :representant do
    dossier_entreprise

    factory :representant_pm, aliases: [:representant_pm_with_complete_address] do
      type_representant { 'P. Morale' }
      forme_juridique { 'Société par actions simplifiée' }
      denomination { 'Grosse Entreprise de Télécom' }
      siren_pm { '000000000' }
      qualite { 'Contrôleur des comptes' }
      conjoint_collab_date_fin { '' }
      id_representant { rand(20) }
      date_derniere_modification { '2017-03-30' }
      libelle_derniere_modification { 'Nouveau dirigeant' }
      adresse_ligne_1 { '3 bis' }
      adresse_ligne_2 { 'rue des Peupliers' }
      adresse_ligne_3 { 'Zone Industrielle Sud' }
      adresse_code_postal { '34000' }
      adresse_ville { 'Montpellier' }
      adresse_code_commune { '34172' }
      adresse_pays { 'FRANCE' }
      code_greffe { '9898' }
      numero_gestion { '2012B01234' }

      factory :president_pm do
        qualite { 'Président' }
        siren_pm { '333444555' }
      end
    end

    factory :representant_pp, aliases: [:representant_pp_with_incomplete_address] do
      type_representant { 'P.Physique' }
      qualite { 'Directeur Associé' }
      id_representant { rand(20) }
      date_derniere_modification { '2016-09-20' }
      libelle_derniere_modification { 'Nouveau dirigeant' }
      adresse_ligne_3 { '15 rue de Rivoli' }
      adresse_code_postal { '75001' }
      adresse_ville { 'Paris' }
      adresse_code_commune { '75056' }
      adresse_pays { 'FRANCE' }
      nom_patronyme { 'dupont' }
      prenoms { 'Georges Rémi' }
      date_naissance { '1907-05-22' }
      ville_naissance { 'Etterbeek' }
      pays_naissance { 'BELGIQUE' }
      nationalite { 'Française' }
      code_greffe { '5555' }
      numero_gestion { '2016B00123' }

      factory :president_pp do
        qualite { 'Président' }
      end
    end
  end
end
