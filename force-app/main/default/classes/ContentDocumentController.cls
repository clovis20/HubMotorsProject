public with sharing class ContentDocumentController {

    // Inner wrapper class used to return simplified file metadata to the client (LWC/Flow)
    public class FileWrapper {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String title;
        @AuraEnabled public String thumbnailUrl; // Contém o caminho RELATIVO de DOWNLOAD

        public FileWrapper(ContentDocumentLink cdl, ContentVersion cv) {
            
            // 1. CORREÇÃO FINAL: Usamos o caminho RELATIVO.
            // O Framework Lightning resolverá o host automaticamente para o caminho do arquivo.
            
            this.contentDocumentId = cdl.ContentDocumentId;
            this.title = cv.Title;
            
            // 2. CONSTRUÇÃO DO CAMINHO RELATIVO:
            // Usamos o caminho de download que funcionou (renditionDownload)
            // Note que NÃO há mais a lógica URL.getOrgDomainUrl()
            this.thumbnailUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png'
                + '&versionId=' + cv.Id
                + '&operationContext=CHATTER' // Mantemos o contexto do link funcional
                + '&contentId=' + cdl.ContentDocumentId;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getRelatedFiles(String recordId) {
        List<FileWrapper> fileList = new List<FileWrapper>();
        if (String.isBlank(recordId)) return fileList;

        Set<Id> contentDocumentIds = new Set<Id>();

        // Busca o ContentDocumentLink (relacionamento do arquivo com o registro)
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

        // Busca a ContentVersion mais recente
        Map<Id, ContentVersion> latestVersions = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Title, FileType
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE
        ]) {
            latestVersions.put(cv.ContentDocumentId, cv);
        }

        // Constrói a lista final de Wrappers
        for (ContentDocumentLink cdl : links) {
            ContentVersion cv = latestVersions.get(cdl.ContentDocumentId);
            if (cv != null) {
                fileList.add(new FileWrapper(cdl, cv));
            }
        }

        return fileList;
    }
}