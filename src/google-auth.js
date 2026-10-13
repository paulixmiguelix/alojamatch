// Regressa à raiz da aplicação, incluindo o prefixo do GitHub Pages.
export function oauthReturnUrl(origin,basePath){
  return new URL(basePath || '/', origin).href
}
export function signInWithGoogle(client,origin,basePath){
  return client.auth.signInWithOAuth({
    provider:'google',
    options:{redirectTo:oauthReturnUrl(origin,basePath),queryParams:{prompt:'select_account'}}
  })
}
