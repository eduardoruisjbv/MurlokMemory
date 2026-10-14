local _, MM = ...

local english = GetLocale() ~= "ptBR"
local strings = {
    ["Perfis Murlok"] = "Murlok profiles",
    ["Modo"] = "Mode",
    ["Importar perfil selecionado"] = "Import selected profile",
    ["Selecione um perfil na lista."] = "Select a profile from the list.",
    ["MurlokExport não está instalado ou carregado. Instale/atualize o MurlokExport para fornecer os perfis Murlok."] = "MurlokExport is not installed or loaded. Install/update MurlokExport to provide Murlok profiles.",
    ["Não há perfis para esta especialização e modo."] = "There are no profiles for this specialization and mode.",
    ["Dados atualizados: "] = "Data updated: ",
    ["Carregando dados do personagem…"] = "Loading character data…",
    ["Saia do combate antes de importar um perfil."] = "Leave combat before importing a profile.",
    ["O diálogo de importação de talentos não está disponível. Abra a aba Talentos e tente novamente."] = "The talent import dialog is unavailable. Open the Talents tab and try again.",
    ["Não foi possível abrir o diálogo nativo de importação."] = "Could not open the native import dialog.",
    ["O perfil foi enviado ao diálogo nativo. Revise o nome e confirme a importação no WoW."] = "The profile was sent to the native dialog. Review the name and confirm the import in WoW.",
    ["O addon usa os códigos de talentos distribuídos pelo MurlokExport; ele não altera talentos sem confirmação do jogador."] = "This addon uses talent strings distributed by MurlokExport; it never changes talents without player confirmation.",
    ["Dados fornecidos pelo MurlokExport"] = "Data provided by MurlokExport",
    ["Perfil indisponível"] = "Profile unavailable",
    ["Estilo de arma"] = "Weapon style",
    ["2h = arma de duas mãos"] = "2h = two-handed weapon",
    ["2w = duas armas"] = "2w = dual wield",
    ["rating"] = "rating",
    ["amostra"] = "sample",
    ["Rating da especialização heroica"] = "Hero specialization rating",
    ["Jogadores na amostra"] = "Players in sample",
    ["A posição é deste código; rating e amostra são agregados por talento heroico."] = "This rank belongs to this string; rating and sample size are aggregated by hero talent specialization.",
}

function MM:T(key)
    if english then return strings[key] or key end
    return key
end
