function closeUI() {
    document.getElementById('bank-ui').classList.add('hidden');
    closeAllForms();
    fetch(`https://${GetParentResourceName()}/close`, { method:'POST', body:'{}' });
}

function closeAllForms(){
    document.querySelectorAll('.transaction-form.modal').forEach(f => {
        f.classList.remove('show');
        f.classList.add('hidden');
    });
}

function toggleDepositForm(){ 
    closeAllForms(); 
    const form = document.getElementById('deposit-form');
    form.classList.remove('hidden');
    form.classList.add('show');
}

function toggleWithdrawForm(){ 
    closeAllForms(); 
    const form = document.getElementById('withdraw-form');
    form.classList.remove('hidden');
    form.classList.add('show');
}

function toggleTransferForm(){ 
    closeAllForms(); 
    const form = document.getElementById('transfer-form');
    form.classList.remove('hidden');
    form.classList.add('show');
}

function closeModal(formId){
    const form = document.getElementById(formId);
    form.classList.remove('show');
    form.classList.add('hidden');
}

function sendDeposit(e){
    e.preventDefault();
    const amount = Number(document.getElementById('deposit-amount').value);
    if(amount > 0){
        fetch(`https://${GetParentResourceName()}/deposit`, { method:'POST', body: JSON.stringify({amount}) });
        document.getElementById('deposit-form').reset();
        closeModal('deposit-form');
    } else alert('❌ Wprowadź poprawną kwotę.');
}

function sendWithdraw(e){
    e.preventDefault();
    const amount = Number(document.getElementById('withdraw-amount').value);
    if(amount > 0){
        fetch(`https://${GetParentResourceName()}/withdraw`, { method:'POST', body: JSON.stringify({amount}) });
        document.getElementById('withdraw-form').reset();
        closeModal('withdraw-form');
    } else alert('❌ Wprowadź poprawną kwotę.');
}
function sendTransfer(e){
    e.preventDefault();
    const target = document.getElementById('transfer-to').value.trim();
    const title  = document.getElementById('transferTitle').value.trim();
    const amount = Number(document.getElementById('transfer-amount').value);

    if(target && amount > 0){
        fetch(`https://${GetParentResourceName()}/transfer`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ targetAccount: target, amount: amount, title: title })
        });
        document.getElementById('transfer-form').reset();
        closeModal('transfer-form');
    } else {
        alert('❌ Wprowadź poprawne dane przelewu.');
    }
}

function renderTransactions(transactions){
    const list = document.getElementById('transactions-list');
    list.innerHTML = '';

    if(!Array.isArray(transactions) || transactions.length === 0){
        list.innerHTML = '<p>Brak historii transakcji</p>';
        return;
    }

    transactions.forEach((t) => {
        const div = document.createElement('div');
        div.className = 'transaction new';

        let desc = '', amountText = '', sign = '-', cls = 'negative';
        const amount = Math.floor(Number(t.amount));

        if(t.type === 'deposit'){
            desc = 'Wpłata';
            sign = '+';
            cls = 'positive';
            amountText = `${sign}${amount} $`;
        } else if(t.type === 'withdraw'){
            desc = 'Wypłata';
            sign = '-';
            cls = 'negative';
            amountText = `${sign}${amount} $`;
        } else if(t.type === 'transfer_out'){
            desc = `Przelew → ${t.target_account || 'Nieznane konto'}`;
            if(t.title) desc += ` (${t.title})`;
            sign = '-';
            cls = 'negative';
            amountText = `${sign}${amount} $`;
        } else if(t.type === 'transfer_in'){
            desc = `Przelew ← ${t.from_account || 'Nieznane konto'}`;
            if(t.title) desc += ` (${t.title})`;
            sign = '+';
            cls = 'positive';
            amountText = `${sign}${amount} $`;
        } else{
            desc = t.type || 'Inne';
            amountText = `${amount} $`;
        }

        const date = t.created_at || t.createdAt || '';

        div.innerHTML = `
            <div style="display:flex;justify-content:space-between;gap:10px;align-items:center;">
                <div style="flex:1">
                    <div class="type">${desc}</div>
                    <div class="date" style="font-size:12px;color:#b9b9b9">${date}</div>
                </div>
                <div>
                    <div class="amount ${cls}" style="font-weight:700">${amountText}</div>
                </div>
            </div>
        `;

        list.appendChild(div);
    });
}

window.addEventListener('message', (event)=>{
    const data = event.data;
    if(data.type==='open'){
        document.getElementById('account-name').innerText = data.account.name || "Brak imienia";
        document.getElementById('account-id').innerText = data.account.account_number || "Brak numeru";
        document.getElementById('account-balance').innerText = Number(data.account.balance || 0).toLocaleString('pl-PL')+' $';
        renderTransactions(data.transactions || []);
        document.getElementById('bank-ui').classList.remove('hidden');
        closeAllForms();
    }
    if(data.type==='balanceUpdate'){
        document.getElementById('account-balance').innerText = Number(data.balance || 0).toLocaleString('pl-PL')+' $';
    }
    if(data.type==='transactionsUpdate'){
        renderTransactions(data.transactions || []);
    }
});
