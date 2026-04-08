-- =============================================================================
-- AUTÔMATO DE EXIBIÇÃO — init.lua
-- Máquina de estados para o mostrador Yazi
-- Nomenclatura inspirada em: A. M. Turing, "On Computable Numbers" (1936)
-- =============================================================================

-- Tabela de símbolos cromáticos da fita de saída visual
local CromaticasDaFitaDeExibicao = {
  ciano        = "#b026ff",
  ciano_choque = "#00f5ff",
  rosa         = "#ff2ea6",
  amarelo      = "#ffb36b",
  violeta      = "#8b7dff",
  laranja      = "#ff9e57",
  verde_neon   = "#39ff88",
  vermelho     = "#ff1744",
  neutro       = "#6125e8",
  azul_abissal = "#08111f",
  fundo_escuro = "#070b17",
  preto        = "#000000",
}

-- =============================================================================
-- TABELA DE TRANSIÇÃO DO SUBSISTEMA DE CONTROLE DE VERSÃO (API externa)
-- Nomenclatura dos campos preservada por obrigação contratual da API do módulo
-- =============================================================================

th.git = th.git or {}
th.git.unknown   = ui.Style():fg(CromaticasDaFitaDeExibicao.neutro)
th.git.modified  = ui.Style():fg(CromaticasDaFitaDeExibicao.ciano)
th.git.added     = ui.Style():fg(CromaticasDaFitaDeExibicao.verde_neon)
th.git.untracked = ui.Style():fg(CromaticasDaFitaDeExibicao.amarelo)
th.git.ignored   = ui.Style():fg(CromaticasDaFitaDeExibicao.neutro)
th.git.deleted   = ui.Style():fg(CromaticasDaFitaDeExibicao.vermelho):bold()
th.git.updated   = ui.Style():fg(CromaticasDaFitaDeExibicao.rosa)
th.git.clean     = ui.Style():fg(CromaticasDaFitaDeExibicao.violeta)

th.git.unknown_sign   = ""
th.git.modified_sign  = "󰏫 "
th.git.added_sign     = "󰐖 "
th.git.untracked_sign = "󰎔 "
th.git.ignored_sign   = "󰦨 "
th.git.deleted_sign   = "󰆴 "
th.git.updated_sign   = "󰚰 "
th.git.clean_sign     = ""

-- Inicializa o módulo de controle de versão apenas se a transição for válida
local transicao_git_aceita, modulo_de_controle_versao = pcall(require, "git")
if transicao_git_aceita then
  modulo_de_controle_versao:setup { order = 1500 }
end

-- =============================================================================
-- TRANSDUTOR DE PERMISSÕES
-- Converte uma trinca de símbolos {r,w,x,s,t,-} no conjunto de operações legíveis
-- Analogia direta à função de transição δ da máquina de Turing
-- =============================================================================

local function transducir_trinca_de_permissoes(trinca_de_simbolos)
  local conjunto_de_operacoes_computadas = {}

  if trinca_de_simbolos:sub(1, 1) == "r" then
    table.insert(conjunto_de_operacoes_computadas, "leitura")
  end
  if trinca_de_simbolos:sub(2, 2) == "w" then
    table.insert(conjunto_de_operacoes_computadas, "modificacao")
  end

  local simbolo_de_execucao = trinca_de_simbolos:sub(3, 3)
  if simbolo_de_execucao == "x"
  or simbolo_de_execucao == "s"
  or simbolo_de_execucao == "t"
  or simbolo_de_execucao == "S"
  or simbolo_de_execucao == "T" then
    table.insert(conjunto_de_operacoes_computadas, "execucao")
  end

  if #conjunto_de_operacoes_computadas == 0 then return "nulo" end
  return string.upper(table.concat(conjunto_de_operacoes_computadas, "/"))
end

local function bloco_powerline(texto, cor_de_fundo, cor_de_entrada)
  local seta = ui.Span("")
    :fg(cor_de_fundo)

  if cor_de_entrada then
    seta = seta:bg(cor_de_entrada)
  end

  return {
    seta,
    ui.Span(" " .. texto .. " ")
      :fg(CromaticasDaFitaDeExibicao.preto)
      :bg(cor_de_fundo)
      :bold(),
  }
end

local function bloco_powerline_custom(texto, cor_do_texto, cor_de_fundo, cor_de_entrada, padding_x)
  local seta = ui.Span("")
    :fg(cor_de_fundo)

  if cor_de_entrada then
    seta = seta:bg(cor_de_entrada)
  end

  local padding = string.rep(" ", padding_x or 1)

  return {
    seta,
    ui.Span(padding .. texto .. padding)
      :fg(cor_do_texto)
      :bg(cor_de_fundo)
      :bold(),
  }
end

local function computar_largura_da_saida(widget)
  local candidatos = {
    function()
      local metodo_area = widget and widget.area
      if type(metodo_area) ~= "function" then return nil end

      local area = widget:area()
      return area and area.w or nil
    end,
    function() return tonumber(os.getenv("YAZI_LEVEL")) and tonumber(os.getenv("COLUMNS")) end,
    function() return tonumber(os.getenv("COLUMNS")) end,
  }

  for _, candidato in ipairs(candidatos) do
    local transicao_valida, largura = pcall(candidato)
    if transicao_valida and type(largura) == "number" and largura > 0 then
      return largura
    end
  end

  return 160
end

local function compactar_fita_de_permissoes(fita_de_permissoes)
  return fita_de_permissoes:sub(2, 10):gsub("-", ".")
end

local function achatar_blocos_em_linha(blocos)
  local linha_de_saida = {}

  for _, bloco in ipairs(blocos) do
    for _, segmento in ipairs(bloco) do
      table.insert(linha_de_saida, segmento)
    end
  end

  return ui.Line(linha_de_saida)
end

local function selecionar_blocos_por_largura(variantes, largura_disponivel)
  local ultima_linha = ui.Line({})

  for _, variante in ipairs(variantes) do
    local linha = achatar_blocos_em_linha(variante.blocos)
    ultima_linha = linha

    local folga_minima = variante.folga_minima or 0
    if linha:width() + folga_minima <= largura_disponivel then
      return linha
    end
  end

  return ultima_linha
end

-- =============================================================================
-- LOCALIZADOR DO REGISTRADOR DE SAÍDA
-- Detecta qual cabeça de escrita está disponível na arquitetura atual
-- =============================================================================

local function localizar_registrador_de_saida()
  if Header and Header.children_add and Header.RIGHT then
    return Header, Header.RIGHT
  end
  return Status, Status.RIGHT
end

-- =============================================================================
-- COMPUTADOR DA CADEIA DE PERMISSÕES
-- Lê a célula sob a cabeça de leitura e emite a fita de permissões formatada
-- =============================================================================

local function computar_cadeia_de_permissoes(widget)
  local celula_sob_a_cabeca_de_leitura = cx.active.current.hovered
  if not celula_sob_a_cabeca_de_leitura or ya.target_family() ~= "unix" then
    return ui.Line({})  -- Estado de rejeição: fita de entrada vazia ou sistema não-Unix
  end

  local fita_de_permissoes = celula_sob_a_cabeca_de_leitura.cha
    and celula_sob_a_cabeca_de_leitura.cha:perm()
    or nil
  if not fita_de_permissoes or #fita_de_permissoes < 10 then
    return ui.Line({})  -- Estado de rejeição: comprimento da fita abaixo do mínimo
  end

  -- Leitura dos três segmentos da fita de permissões: proprietário, coletividade, terceiros
  local simbolos_do_proprietario = transducir_trinca_de_permissoes(fita_de_permissoes:sub(2, 4))
  local simbolos_da_coletividade = transducir_trinca_de_permissoes(fita_de_permissoes:sub(5, 7))
  local simbolos_de_terceiros    = transducir_trinca_de_permissoes(fita_de_permissoes:sub(8, 10))
  local fita_de_permissoes_compacta = compactar_fita_de_permissoes(fita_de_permissoes)
  local largura_da_saida = computar_largura_da_saida(widget)

  local assinatura_de_rede = "╾━╤デ╦︻ (·_- ) Ⓐ"
  local tag_do_operador = "[ OPERADOR: braga.uss ]"
  local assinatura_minima = "Ⓐ"
  local folga_para_assinatura_completa = 18

  -- Estado de aceitação: emite a linha de saída formatada na fita de exibição
  local variantes = {
    {
      blocos = {
        bloco_powerline("TERCEIROS: " .. simbolos_de_terceiros, CromaticasDaFitaDeExibicao.amarelo, nil),
        bloco_powerline("COLETIVIDADE: " .. simbolos_da_coletividade, CromaticasDaFitaDeExibicao.laranja, CromaticasDaFitaDeExibicao.amarelo),
        bloco_powerline("LEITURA/MODIFICACAO: " .. simbolos_do_proprietario, CromaticasDaFitaDeExibicao.violeta, CromaticasDaFitaDeExibicao.laranja),
        bloco_powerline_custom(assinatura_de_rede, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.violeta),
        bloco_powerline_custom(tag_do_operador, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, 2),
      },
      folga_minima = folga_para_assinatura_completa,
    },
    {
      blocos = {
        bloco_powerline("TERCEIROS: " .. simbolos_de_terceiros, CromaticasDaFitaDeExibicao.amarelo, nil),
        bloco_powerline("COLETIVIDADE: " .. simbolos_da_coletividade, CromaticasDaFitaDeExibicao.laranja, CromaticasDaFitaDeExibicao.amarelo),
        bloco_powerline("LEITURA/MODIFICACAO: " .. simbolos_do_proprietario, CromaticasDaFitaDeExibicao.violeta, CromaticasDaFitaDeExibicao.laranja),
        bloco_powerline_custom(assinatura_minima, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.violeta),
        bloco_powerline_custom(tag_do_operador, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, 2),
      },
    },
    {
      blocos = {
        bloco_powerline("PROP: " .. simbolos_do_proprietario, CromaticasDaFitaDeExibicao.violeta, nil),
        bloco_powerline("COL: " .. simbolos_da_coletividade, CromaticasDaFitaDeExibicao.laranja, CromaticasDaFitaDeExibicao.violeta),
        bloco_powerline("TER: " .. simbolos_de_terceiros, CromaticasDaFitaDeExibicao.amarelo, CromaticasDaFitaDeExibicao.laranja),
        bloco_powerline_custom(assinatura_minima, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.violeta),
        bloco_powerline_custom(tag_do_operador, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, 2),
      },
    },
    {
      blocos = {
        bloco_powerline("LEITURA/MODIFICACAO: " .. simbolos_do_proprietario, CromaticasDaFitaDeExibicao.violeta, nil),
        bloco_powerline_custom(tag_do_operador, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, 2),
      },
    },
    {
      blocos = {
        bloco_powerline("PERM: " .. fita_de_permissoes_compacta, CromaticasDaFitaDeExibicao.amarelo, nil),
        bloco_powerline_custom(tag_do_operador, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, 2),
      },
    },
    {
      blocos = {
        bloco_powerline(fita_de_permissoes_compacta, CromaticasDaFitaDeExibicao.amarelo, nil),
        bloco_powerline_custom(tag_do_operador, CromaticasDaFitaDeExibicao.azul_abissal, CromaticasDaFitaDeExibicao.ciano_choque, CromaticasDaFitaDeExibicao.azul_abissal, 2),
      },
    },
  }

  return selecionar_blocos_por_largura(variantes, largura_da_saida)
end

-- =============================================================================
-- ACOPLAMENTO DO COMPUTADOR AO REGISTRADOR DE SAÍDA
-- =============================================================================

local registrador_de_saida, posicao_de_escrita_na_fita = localizar_registrador_de_saida()

registrador_de_saida:children_add(function(self)
  local transicao_valida, cadeia_de_saida = pcall(computar_cadeia_de_permissoes, self)
  if not transicao_valida then
    -- Estado de erro: a máquina entra em halt e emite diagnóstico
    ya.notify({
      title   = "HALT — erro de computacao na fita de exibicao",
      content = tostring(cadeia_de_saida),
      level   = "error",
      timeout = 5,
    })
    return ui.Line({})
  end
  return cadeia_de_saida
end, 500, posicao_de_escrita_na_fita)

-- =============================================================================
-- LINEMODE: EXIBIÇÃO DE TAMANHO + DATA DE MODIFICAÇÃO
-- Ativado em `yazi.toml` como `size_and_mtime` para aumentar a densidade de informação.
-- =============================================================================

function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%b %d %H:%M", time)
	else
		time = os.date("%b %d  %Y", time)
	end

	local size = self._file:size()
	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end
