const formatINR = (val) =>
    `₹${Number(val).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

// Theme persistence (Light / Dark)
const rootEl = document.documentElement;
const themeToggle = document.getElementById('theme-toggle');
const themeLabel = document.getElementById('theme-label');

function applyTheme(theme) {
    rootEl.setAttribute('data-theme', theme);
    localStorage.setItem('gareebsql-theme', theme);
    themeLabel.textContent = theme === 'dark' ? 'LIGHT MODE' : 'DARK MODE';
}

applyTheme(localStorage.getItem('gareebsql-theme') || 'dark');

themeToggle.addEventListener('click', () => {
    const nextTheme = rootEl.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    applyTheme(nextTheme);
});

// Tab navigation
document.querySelectorAll('.tab-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach((b) => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach((c) => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(btn.dataset.tab).classList.add('active');
    });
});

async function loadDashboard() {
    const res = await fetch('/api/dashboard');
    const data = await res.json();

    const totalDeposits = data.accounts.reduce((sum, acc) => sum + Number(acc.balance), 0);
    const activeLoans = data.loans.filter((l) => l.status === 'Active');
    const totalLoanRemaining = activeLoans.reduce((sum, l) => sum + Number(l.remaining_principal), 0);

    document.getElementById('stats-grid').innerHTML = `
        <div class="kpi-card"><div class="label">Total Bank Liquidity</div><div class="value">${formatINR(totalDeposits)}</div></div>
        <div class="kpi-card"><div class="label">Active Accounts</div><div class="value">${data.accounts.length}</div></div>
        <div class="kpi-card"><div class="label">Registered Customers</div><div class="value">${data.customers.length}</div></div>
        <div class="kpi-card"><div class="label">Active Loan Exposure</div><div class="value">${formatINR(totalLoanRemaining)}</div></div>
    `;

    document.querySelector('#accounts-table tbody').innerHTML = data.accounts.map((a) => `
        <tr>
            <td><code>${a.account_number}</code></td>
            <td><strong>${a.full_name}</strong></td>
            <td>${a.branch_name}</td>
            <td>${a.account_type}</td>
            <td class="num"><strong>${formatINR(a.balance)}</strong></td>
            <td><span class="tag ${a.status === 'Active' ? 'pos' : 'warn'}">${a.status}</span></td>
        </tr>
    `).join('');

    document.querySelector('#customer-view-table tbody').innerHTML = data.customers.map((c) => `
        <tr>
            <td><strong>${c.full_name}</strong></td>
            <td>${c.city}</td>
            <td class="num">${c.total_accounts}</td>
            <td class="num"><strong>${formatINR(c.total_balance)}</strong></td>
        </tr>
    `).join('');

    document.querySelector('#loan-view-table tbody').innerHTML = data.loans.map((l) => `
        <tr>
            <td><strong>${l.full_name}</strong></td>
            <td>${l.loan_type}</td>
            <td class="num">${formatINR(l.principal_amount)}</td>
            <td class="num">${formatINR(l.total_paid)}</td>
            <td class="num"><strong>${formatINR(l.remaining_principal)}</strong></td>
            <td><span class="tag ${l.status === 'Active' ? 'warn' : l.status === 'Closed' ? 'pos' : 'neg'}">${l.status}</span></td>
        </tr>
    `).join('');

    const accountOptions = data.accounts
        .map((a) => `<option value="${a.account_number}">${a.account_number} · ${a.full_name} (${formatINR(a.balance)})</option>`)
        .join('');

    document.getElementById('from-account').innerHTML = accountOptions;
    document.getElementById('to-account').innerHTML = accountOptions;
    if (data.accounts.length > 1) {
        document.getElementById('to-account').selectedIndex = 1;
    }

    const filterSelect = document.getElementById('statement-filter');
    const currentFilter = filterSelect.value;
    filterSelect.innerHTML =
        `<option value="">All Accounts</option>` +
        data.accounts.map((a) => `<option value="${a.account_number}">${a.account_number} (${a.full_name})</option>`).join('');
    filterSelect.value = currentFilter;
}

async function loadStatements(accountNumber = '') {
    const url = accountNumber
        ? `/api/statements?account_number=${encodeURIComponent(accountNumber)}`
        : '/api/statements';
    const res = await fetch(url);
    const data = await res.json();

    document.querySelector('#statements-table tbody').innerHTML = data.transactions.map((t) => {
        const isCredit = t.type === 'Deposit' || t.type === 'Transfer_In';
        return `
            <tr>
                <td><code>#${t.transaction_id}</code></td>
                <td><code>${t.account_number}</code></td>
                <td>${t.full_name}</td>
                <td><span class="tag ${isCredit ? 'pos' : 'neg'}">${t.type}</span></td>
                <td class="num">${isCredit ? '+' : '-'}${formatINR(t.amount)}</td>
                <td class="num"><strong>${formatINR(t.running_balance)}</strong></td>
                <td>${new Date(t.txn_date).toLocaleString('en-IN')}</td>
                <td>${t.remarks || '—'}</td>
            </tr>
        `;
    }).join('');
}

async function loadAnalytics() {
    const res = await fetch('/api/analytics');
    const data = await res.json();

    document.querySelector('#ranking-table tbody').innerHTML = data.rankings.map((r) => `
        <tr>
            <td><code>#${r.balance_rank}</code></td>
            <td><strong>${r.full_name}</strong></td>
            <td class="num"><strong>${formatINR(r.total_balance)}</strong></td>
        </tr>
    `).join('');

    document.querySelector('#cashflow-table tbody').innerHTML = data.cash_flow.map((cf) => `
        <tr>
            <td><code>${cf.month}</code></td>
            <td class="num" style="color: var(--pos)">+${formatINR(cf.inflow)}</td>
            <td class="num" style="color: var(--neg)">-${formatINR(cf.outflow)}</td>
            <td class="num"><strong>${formatINR(cf.net_flow)}</strong></td>
        </tr>
    `).join('');

    document.querySelector('#debtfree-table tbody').innerHTML = data.debt_free.map((d) => `
        <tr>
            <td><code>#${d.customer_id}</code></td>
            <td><strong>${d.full_name}</strong></td>
            <td>${d.city}</td>
        </tr>
    `).join('');

    document.querySelector('#referral-table tbody').innerHTML = data.referrals.map((ref) => `
        <tr>
            <td><strong>${ref.customer}</strong></td>
            <td>${ref.referred_by}</td>
        </tr>
    `).join('');
}

document.getElementById('statement-filter').addEventListener('change', (e) => {
    loadStatements(e.target.value);
});

document.getElementById('transfer-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const feedback = document.getElementById('transfer-feedback');
    feedback.className = 'feedback hidden';

    const payload = {
        from_account: document.getElementById('from-account').value,
        to_account: document.getElementById('to-account').value,
        amount: parseFloat(document.getElementById('amount').value),
        remarks: document.getElementById('remarks').value || 'Online fund transfer'
    };

    const res = await fetch('/api/transfer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });
    const result = await res.json();

    if (res.ok) {
        feedback.textContent = `COMMITTED: ${result.message}`;
        feedback.className = 'feedback success';
        document.getElementById('amount').value = '';
        await Promise.all([loadDashboard(), loadStatements(), loadAnalytics()]);
    } else {
        feedback.textContent = `ROLLED BACK: ${result.detail || 'Transfer rejected'}`;
        feedback.className = 'feedback error';
    }
});

(async function init() {
    await Promise.all([loadDashboard(), loadStatements(), loadAnalytics()]);
})();