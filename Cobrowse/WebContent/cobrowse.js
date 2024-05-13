(function(w,t,c,p,s,e){p=new Promise(function(r){w[c]={client:function(){if(!s){
s=document.createElement(t);s.src='https://js.cobrowse.io/CobrowseIO.js';s.async=1;
e=document.getElementsByTagName(t)[0];e.parentNode.insertBefore(s,e);s.onload=function()
{r(w[c]);};}return p;}};});})(window,'script','CobrowseIO');

CobrowseIO.trustedOrigins = [
    'https://cobrowse-sdk-js-examples.cbrws.io'
];   

(async () => {
    await CobrowseIO.client();
    await CobrowseIO.start();
})();