public class FileWrapper {
    @AuraEnabled public String contentDocumentId;
    @AuraEnabled public String title;
    @AuraEnabled public String thumbnailUrl;

    public FileWrapper(ContentDocumentLink cdl, ContentVersion cv) {
        this.contentDocumentId = cdl.ContentDocumentId;
        this.title = cv.Title;
        this.thumbnailUrl = '/sfc/servlet.shepherd/version/rendition?rendition=THUMB720BY480&versionId=' + cv.Id;
    }
}

public with sharing class ContentDocumentController {
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
