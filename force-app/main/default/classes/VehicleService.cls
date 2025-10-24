public with sharing class VehicleService {

    /**
    * Método para obter a ContentDocumentId da primeira imagem anexada a um registro de Veículo.
    */
    @AuraEnabled(cacheable=true)
    public static String getVehicleImageId(String recordId) {
        if (String.isBlank(recordId)) {
            return null;
        }

        // Correção: Usamos SystemModstamp para ordenar, pois CreatedDate não é acessível/indexado em ContentDocumentLink.
        List<ContentDocumentLink> cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY SystemModstamp ASC // Campo que existe e permite ordenação
            LIMIT 1
        ];

        if (!cdl.isEmpty()) {
            return cdl[0].ContentDocumentId;
        }

        return null;
    }
}