public with sharing class VehicleService {

    /**
     * Wrapper DTO para entregar informações de imagem para o LWC
     */
    public class VehicleImageInfo {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public Id latestVersionId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
    }

    /**
     * Retorna a ContentDocumentId que será usada como imagem principal do veículo.
     * Primeiro tenta usar o campo custom `Primary_Image_Document_Id__c` do Vehicle__c (se preenchido
     * e estiver vinculado ao registro). Caso contrário, faz fallback para a imagem mais recente
     * vinculada ao registro (ordenando por SystemModstamp DESC).
     */
    @AuraEnabled(cacheable=true)
    public static String getVehicleImageId(String recordId) {
        if (String.isBlank(recordId)) {
            return null;
        }

        // Tenta primeiro usar o campo custom no Vehicle__c
        Vehicle__c v = [SELECT Id, Primary_Image_Document_Id__c FROM Vehicle__c WHERE Id = :recordId LIMIT 1];
        if (v != null && v.Primary_Image_Document_Id__c != null) {
            // Verifica se este ContentDocument está realmente ligado ao registro
            List<ContentDocumentLink> checkLink = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                  AND ContentDocumentId = :v.Primary_Image_Document_Id__c
                LIMIT 1
            ];
            if (!checkLink.isEmpty()) {
                return v.Primary_Image_Document_Id__c;
            }
        }

        // Fallback: busca a imagem mais recentemente modificada/publicada vinculada ao registro
        List<ContentDocumentLink> cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY SystemModstamp DESC
            LIMIT 1
        ];

        if (!cdl.isEmpty()) {
            return cdl[0].ContentDocumentId;
        }

        return null;
    }

    /**
     * Retorna a lista de imagens (ContentDocument) vinculadas ao veículo, com informações úteis
     * para renderização de thumbs no LWC.
     */
    @AuraEnabled(cacheable=true)
    public static List<VehicleImageInfo> getVehicleImages(Id recordId) {
        List<VehicleImageInfo> result = new List<VehicleImageInfo>();
        if (recordId == null) return result;

        // Busca ContentDocumentLink e traz campos do ContentDocument
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.FileType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY SystemModstamp DESC
        ];

        for (ContentDocumentLink l : links) {
            VehicleImageInfo info = new VehicleImageInfo();
            info.contentDocumentId = l.ContentDocumentId;
            info.latestVersionId = l.ContentDocument.LatestPublishedVersionId;
            info.title = l.ContentDocument.Title;
            info.fileType = l.ContentDocument.FileType;
            result.add(info);
        }

        return result;
    }

    /**
     * Define programaticamente a imagem principal (capa) do veículo, gravando o ContentDocumentId
     * no campo `Primary_Image_Document_Id__c` do Vehicle__c. Retorna true se ok.
     */
    @AuraEnabled
    public static Boolean setPrimaryVehicleImage(Id recordId, Id contentDocumentId) {
        if (recordId == null || contentDocumentId == null) return false;

        try {
            // Verifica se o ContentDocument está ligado ao registro
            Integer cnt = [SELECT COUNT()
                           FROM ContentDocumentLink
                           WHERE LinkedEntityId = :recordId
                             AND ContentDocumentId = :contentDocumentId];
            if (cnt == 0) {
                // Não permitido definir uma imagem que não esteja vinculada
                return false;
            }

            Vehicle__c v = new Vehicle__c(Id = recordId);
            v.Primary_Image_Document_Id__c = (String)contentDocumentId;
            update v;
            return true;
        } catch (Exception e) {
            System.debug('Erro em setPrimaryVehicleImage: ' + e);
            return false;
        }
    }
}