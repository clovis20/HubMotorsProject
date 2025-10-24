import { LightningElement, api, wire } from 'lwc';
import getRelatedFiles from '@salesforce/apex/ContentDocumentController.getRelatedFiles';

export default class FileSelector extends LightningElement {
    @api recordId; // Recebe o ID do Flow/Página de Registro
    @api selectedFileId = ''; // Variável de saída para o Flow
    files;
    error;

    @wire(getRelatedFiles, { recordId: '$recordId' })
    wiredFiles({ error, data }) {
        if (data) {
            this.files = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.files = undefined;
            console.error('Erro ao buscar arquivos:', error);
        }
    }

    handleSelection(event) {
        const selectedId = event.currentTarget.dataset.fileId;
        this.selectedFileId = selectedId;

        this.template.querySelectorAll('.file-card').forEach(card => {
            card.classList.remove('selected-card');
        });
        event.currentTarget.classList.add('selected-card');

        // Notify Flow that output property changed
        this.dispatchEvent(new CustomEvent('change'));
    }

    get isFileSelected() {
        return this.selectedFileId !== '';
    }
}
