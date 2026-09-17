// Configuración pública del frontend.
// La URL de Supabase y la publishable key son valores de cliente, no secretos.
// NUNCA poner aquí service_role, secret keys, contraseñas ni tokens privados.
window.GABT_CONFIG = {
  supabaseUrl: '',
  supabasePublishableKey: '',
  authProvider: 'azure', // 'azure' para Microsoft 365 / Entra ID; 'google' para Google Workspace.
  allowedDomain: 'electricabt.com'
};
