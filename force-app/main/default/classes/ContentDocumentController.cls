public with sharing class ContentDocumentController {

    public class FileWrapper {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String title;
        @AuraEnabled public String thumbnailUrl; // Agora conterá o URL de DOWNLOAD

        public FileWrapper(ContentDocumentLink cdl, ContentVersion cv) {
            
            // 1. Obter o URL Base do Domínio de Arquivo (Correção para o domínio cruzado)
            String baseUrl = URL.getOrgDomainUrl().toExternalForm(); 
            String fileDomainUrl = baseUrl.replace('.my.salesforce.com', '.trailblaze.file.force.com')
                                          .replace('.lightning.force.com', '.trailblaze.file.force.com');
            
            this.contentDocumentId = cdl.ContentDocumentId;
            this.title = cv.Title;
            
            // 2. CONSTRUÇÃO FINAL DA URL: USANDO O DOWNLOAD DO ARQUIVO ORIGINAL (FUNCIONALIDADE GARANTIDA)
            // Usa o ID da ContentVersion para o download
            this.thumbnailUrl = fileDomainUrl 
                + '/sfc/servlet.shepherd/version/download/' + cv.Id 
                + '?operationContext=DETAIL'
                + '&contentId=' + cdl.ContentDocumentId;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getRelatedFiles(String recordId) {
        List<FileWrapper> fileList = new List<FileWrapper>();
        if (String.isBlank(recordId)) return fileList;

        Set<Id> contentDocumentIds = new Set<Id>();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];

        if (links.isEmpty()) {
            return fileList;
        }

        for (ContentDocumentLink cdl : links) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }

        Map<Id, ContentVersion> latestVersions = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Title, FileType
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE
        ]) {
            latestVersions.put(cv.ContentDocumentId, cv);
        }

        for (ContentDocumentLink cdl : links) {
            ContentVersion cv = latestVersions.get(cdl.ContentDocumentId);
            if (cv != null) {
                fileList.add(new FileWrapper(cdl, cv));
            }
        }

        return fileList;
    }
}