@IsTest
private class TestVehicleService {

    // Método de utilidade para criar os dados de teste no banco de dados.
    private static Id setupTestData(Boolean createAttachment) {
        // 1. Cria e insere um registro de Veículo (Vehicle__c)
        Vehicle__c newVehicle = new Vehicle__c(
            // **CAMPOS CORRIGIDOS:** Garante que todos os campos da Fase 1 estejam presentes.
            Name = 'Test Car 1',
            Make__c = 'Honda',
            Model__c = 'Civic', // O campo que estava faltando no seu erro
            Year__c = 2022,
            Price__c = 25000,
            Mileage__c = 10000,
            Stock_Status__c = 'Available'
        );
        insert newVehicle;

        if (createAttachment) {
            // 2. Cria ContentVersion e ContentDocument
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Photo';
            cv.PathOnClient = 'TestPhoto.jpg';
            cv.VersionData = Blob.valueOf('Test Content Data');
            insert cv;

            ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

            // 3. Cria ContentDocumentLink (vincula o arquivo ao Veículo)
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cd.Id;
            cdl.LinkedEntityId = newVehicle.Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
        }

        return newVehicle.Id;
    }

    @IsTest
    static void testGetVehicleImageId_Success() {
        // Cenário 1: Veículo tem um anexo de foto. Deve retornar a ContentDocumentId.

        // SETUP: Cria um Veículo COM anexo.
        Id vehicleId = setupTestData(true);

        // TEST: Inicia o bloco de teste.
        Test.startTest();
        String resultId = VehicleService.getVehicleImageId(vehicleId);
        Test.stopTest();

        // ASSERT: Verifica se a ID foi retornada e ajusta a verificação de comprimento.
        System.assertNotEquals(null, resultId, 'O método deve retornar uma ContentDocumentId válida.');
        // CORREÇÃO: Usar 18, pois o sistema de teste retornou 18 caracteres.
        System.assertEquals(18, resultId.length(), 'A ContentDocumentId deve ter o comprimento de 18 caracteres no contexto de teste.');
    }

    @IsTest
    static void testGetVehicleImageId_NoAttachment() {
        // Cenário 2: Veículo NÃO tem anexos. Deve retornar nulo.

        // SETUP: Cria um Veículo SEM anexo.
        Id vehicleId = setupTestData(false);

        // TEST: Inicia o bloco de teste.
        Test.startTest();
        String resultId = VehicleService.getVehicleImageId(vehicleId);
        Test.stopTest();

        // ASSERT: Verifica se o resultado é nulo.
        System.assertEquals(null, resultId, 'O método deve retornar null quando não houver anexos.');
    }

    @IsTest
    static void testGetVehicleImageId_NullInput() {
        // Cenário 3: O recordId de entrada é nulo. Deve retornar nulo.

        // TEST: Inicia o bloco de teste com entrada nula.
        Test.startTest();
        String resultId = VehicleService.getVehicleImageId(null);
        Test.stopTest();

        // ASSERT: Verifica se o resultado é nulo.
        System.assertEquals(null, resultId, 'O método deve retornar null quando a ID de entrada for nula.');
    }
}