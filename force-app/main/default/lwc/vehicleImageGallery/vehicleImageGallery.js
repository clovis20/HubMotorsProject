import { LightningElement, api, wire } from 'lwc';
// Importa o método Apex que acabamos de criar
import getVehicleImageId from '@salesforce/apex/VehicleService.getVehicleImageId';

export default class VehicleImageGallery extends LightningElement {
    @api recordId; // Recebe o ID do registro de Veículo da página
    vehicleImageId;
    isImageFound = false;

    // Conecta o método Apex. O $recordId garante que a função é re-executada se o ID da página mudar.
    @wire(getVehicleImageId, { recordId: '$recordId' })
    wiredImageId({ error, data }) {
        if (data) {
            this.vehicleImageId = data;
            this.isImageFound = true;
        } else if (error) {
            // Em caso de erro (ex: problema de permissão), apenas loga o erro
            console.error('Erro ao buscar ID da imagem:', error);
            this.isImageFound = false;
        }
    }

    // Propriedade getter que constrói a URL de visualização/download do arquivo
    get imageUrl() {
        // A URL segue o padrão: /sfc/servlet.shepherd/document/download/{ContentDocumentId}
        return this.vehicleImageId ? `/sfc/servlet.shepherd/document/download/${this.vehicleImageId}` : null;
    }
}