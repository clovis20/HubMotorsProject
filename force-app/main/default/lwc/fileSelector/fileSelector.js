import { LightningElement, api, wire } from 'lwc';
import getRelatedFiles from '@salesforce/apex/ContentDocumentController.getRelatedFiles';

export default class FileSelector extends LightningElement {
    @api recordId;
    @api selectedFileId = ''; // Variável de Saída
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
        
        // Atualiza a variável de saída
        this.selectedFileId = selectedId;
        
        // Adiciona classe CSS para destaque (como planejado)
        this.template.querySelectorAll('.file-card').forEach(card => {
            card.classList.remove('selected-card');
        });
        event.currentTarget.classList.add('selected-card');

        // Dispara evento para o Flow
        this.dispatchEvent(new CustomEvent('change'));
    }

    get isFileSelected() {
        return this.selectedFileId !== '';
    }
}