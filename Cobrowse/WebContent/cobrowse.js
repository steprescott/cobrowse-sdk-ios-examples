(async () => {
    const startCobrowse = async () => {
        (async (w, t, c, p, s, e) => {p = new Promise((r) => {w[c] = {client: async () => {if (!s) {
        s = document.createElement(t);s.src = 'https://js.cobrowse.io/CobrowseIO.js';s.async = 1;
        e = document.getElementsByTagName(t)[0];e.parentNode.insertBefore(s, e);s.onload = () =>
        {r(w[c]);};}return p;},};});})(window, 'script', 'CobrowseIO');

        await CobrowseIO.client();

        CobrowseIO.redactedViews = [ '.redacted' ]
        CobrowseIO.trustedOrigins = [
            'https://demo.cobrowse.io'
        ];
        
        
        CobrowseIO.start();
    };

    await startCobrowse();
})();