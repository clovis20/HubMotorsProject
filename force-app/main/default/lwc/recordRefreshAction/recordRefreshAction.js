// recordRefreshAction.js
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi'; // Novo import: Usaremos o método mais moderno de refresh

export default class RecordRefreshAction extends NavigationMixin(LightningElement) {
    
    connectedCallback() {
        // Dispara o evento que notifica a UI de que os dados do registro podem ter mudado.
        // Isso é o método moderno para forçar um "refresh" de dados de @wire.
        getRecordNotifyChange([{recordId: this.recordId}]);
        
        // Em seguida, navega para a mesma página, garantindo o refresh visual completo.
        // O Flow deve terminar logo após.
        this.navigateToCurrentPage();
    }

    navigateToCurrentPage() {
        // Usa a navegação para forçar uma "re-entrada" na mesma página.
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: window.location.href
            }
        });
    }
}