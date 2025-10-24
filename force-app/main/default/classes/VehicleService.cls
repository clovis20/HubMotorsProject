public with sharing class VehicleService {

    /**
    * Método para obter o ContentDocumentId da imagem principal (armazenado em um campo customizado).
    * O campo Main_Image_Id__c deve ser criado no objeto Vehicle__c.
    */
    @AuraEnabled(cacheable=true)
    public static String getVehicleImageId(String recordId) {
        if (String.isBlank(recordId)) {
            return null;
        }

        // Buscamos o ID do arquivo armazenado no campo Main_Image_Id__c
        // Usamos uma consulta dinâmica para evitar a dependência direta se o campo Main_Image_Id__c ainda não existir
        // MAS, para um componente Lightning, é melhor usar a sintaxe fixa se você tiver certeza do campo:

        Vehicle__c vehicleRecord = [
            SELECT Main_Image_Id__c 
            FROM Vehicle__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        // Se o campo Main_Image_Id__c contiver o ID, retornamos ele.
        if (vehicleRecord.Main_Image_Id__c != null) {
            return vehicleRecord.Main_Image_Id__c;
        }
        
        // Se o campo estiver vazio, voltamos para a lógica antiga (primeiro anexo) como fallback,
        // mas é melhor que o campo seja sempre preenchido pelo Flow.
        // Se for essencial que a imagem apareça mesmo sem seleção:
        List<ContentDocumentLink> cdl = [
             SELECT ContentDocumentId
             FROM ContentDocumentLink
             WHERE LinkedEntityId = :recordId
             ORDER BY SystemModstamp DESC // Muda para DESC para pegar o mais recente
             LIMIT 1
         ];

         if (!cdl.isEmpty()) {
             return cdl[0].ContentDocumentId;
         }

        return null;
    }
}