import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Importa os métodos Apex
import getVehicleImageId from '@salesforce/apex/VehicleService.getVehicleImageId';
import getVehicleImages from '@salesforce/apex/VehicleService.getVehicleImages';
import setPrimaryVehicleImage from '@salesforce/apex/VehicleService.setPrimaryVehicleImage';

export default class VehicleImageGallery extends LightningElement {
    @api recordId; // Recebe o ID do registro de Veículo da página
    vehicleImageId;
    isImageFound = false;
    images = []; // lista de imagens do álbum

    // Main image id (prioriza campo custom através do Apex)
    @wire(getVehicleImageId, { recordId: '$recordId' })
    wiredImageId({ error, data }) {
        if (data) {
            this.vehicleImageId = data;
            this.isImageFound = true;
            // atualiza flags nas thumbnails
            this.updateImagesSelection();
        } else {
            this.vehicleImageId = null;
            this.isImageFound = false;
            if (error) {
                console.error('Erro ao buscar ID da imagem:', error);
            }
        }
    }

    // Lista de imagens do veículo (para exibir álbum e permitir seleção)
    @wire(getVehicleImages, { recordId: '$recordId' })
    wiredImages({ error, data }) {
        if (data) {
            // adiciona uma thumbUrl por item — evita chamadas de função no template
            this.images = data.map(item => {
                const thumb = item.latestVersionId
                    ? `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB120BY90&versionId=${item.latestVersionId}`
                    : `/sfc/servlet.shepherd/document/download/${item.contentDocumentId}`;
                return Object.assign({}, item, { thumbUrl: thumb, isPrimary: item.contentDocumentId === this.vehicleImageId });
            });
            // garante que a UI reflita a seleção atual
            this.updateImagesSelection();
        } else if (error) {
            console.error('Erro ao buscar imagens do veículo:', error);
            this.images = [];
        }
    }

    // Constrói a URL para download da imagem principal (ContentDocument)
    get imageUrl() {
        return this.vehicleImageId ? `/sfc/servlet.shepherd/document/download/${this.vehicleImageId}` : null;
    }

    // Constrói URL de miniatura usando LatestPublishedVersionId (se disponível)
    thumbUrl(image) {
        if (!image) return null;
        if (image.latestVersionId) {
            // Rendition menor (thumbnail). Fallback ao download completo se o parâmetro não funcionar em algumas orgs.
            return `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB120BY90&versionId=${image.latestVersionId}`;
        }
        return `/sfc/servlet.shepherd/document/download/${image.contentDocumentId}`;
    }

    // Handler do clique 'Set as Cover'
    async handleSetPrimary(event) {
        const docId = event.currentTarget.dataset.docid;
        if (!docId || !this.recordId) return;

        try {
            const ok = await setPrimaryVehicleImage({ recordId: this.recordId, contentDocumentId: docId });
            if (ok) {
                this.vehicleImageId = docId;
                this.isImageFound = true;
                // atualiza selection nas thumbs
                this.updateImagesSelection();
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Capa atualizada',
                    message: 'Imagem definida como capa com sucesso.',
                    variant: 'success'
                }));
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Não permitido',
                    message: 'Não foi possível definir esta imagem como capa. Verifique se está vinculada ao veículo e suas permissões.',
                    variant: 'warning'
                }));
                console.warn('Não foi possível definir a imagem como principal (verifique vínculos/permissões).');
            }
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Erro',
                message: 'Erro ao definir imagem principal: ' + (err && err.body && err.body.message ? err.body.message : err),
                variant: 'error'
            }));
            console.error('Erro ao definir imagem principal:', err);
        }
    }

    // Atualiza a flag isPrimary em each image com base no vehicleImageId atual
    updateImagesSelection() {
        if (!this.images || !Array.isArray(this.images)) return;
        this.images = this.images.map(item => Object.assign({}, item, { isPrimary: (this.vehicleImageId && item.contentDocumentId === this.vehicleImageId) }));
    }
}