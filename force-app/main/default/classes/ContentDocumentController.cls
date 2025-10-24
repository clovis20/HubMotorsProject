public with sharing class ContentDocumentController {

    // Classe de Invólucro (Wrapper)
    public class FileWrapper {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String title;
        @AuraEnabled public String thumbnailUrl;

        public FileWrapper(ContentDocumentLink cdl, ContentVersion cv) {
            // 1. Obter o URL Base do Domínio da Organização (Ex: .my.salesforce.com)
            String baseUrl = URL.getOrgDomainUrl().toExternalForm(); 
            
            // 2. CORREÇÃO DE DOMÍNIO: Substituir o domínio principal pelo domínio de Arquivo
            // O domínio de arquivo correto na sua org é 'trailblaze.file.force.com' (visto na imagem)
            // Usamos a versão .my.salesforce.com como referência.
            // Se getOrgDomainUrl() retornar o domínio principal de Lightning, vamos trocá-lo.
            
            // Exemplo da substituição de parte do URL para obter o domínio de arquivo:
            // Isso garante que a URL seja como https://seudominio.trailblaze.file.force.com
            String fileDomainUrl = baseUrl.replace('.lightning.force.com', '.file.force.com')
                                          .replace('my.salesforce.com', 'file.force.com');

            this.contentDocumentId = cdl.ContentDocumentId;
            this.title = cv.Title;
            
            // 3. Construir o URL COMPLETO para a miniatura (rendition)
            // O caminho '/sfc/servlet.shepherd/version/rendition' é o caminho correto para renderização.
            this.thumbnailUrl = fileDomainUrl + '/sfc/servlet.shepherd/version/rendition?rendition=THUMB720BY480&versionId=' + cv.Id;
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