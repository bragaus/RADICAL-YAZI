# `YAZI // RADICAL`

```text
██╗   ██╗ █████╗ ███████╗██╗
╚██╗ ██╔╝██╔══██╗╚══███╔╝██║
 ╚████╔╝ ███████║  ███╔╝ ██║
  ╚██╔╝  ██╔══██║ ███╔╝  ██║
   ██║   ██║  ██║███████╗██║
   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝

     [ RADICAL MODE ]
```

> Tunando o  Yazi explorador de arquivos padrão do RADICAL. para parecer um painel de nave espacial: neon, powerline, flavor sombrio e uma assinatura visual cyberpunk e é claro RADICAL!

## `:: stack visual`

- `theme.toml`: palette neon roxo, rosa, laranja e ciano choque.
- `init.lua`: HUD custom em Lua, bloco powerline, status de permissoes e integracao com `git`.
- `yazi.toml`: comportamento do manager, openers, preview cache e fetchers do plugin de git.
- `package.toml`: plugins `jump-fzf`, `jump-zoxide`, `git`, `toggle-pane` e flavor `lain`.
- `yazi-hud`: launcher externo que sobe o `Yazi` dentro de uma moldura animada de terminal.
- `hud_pulse.sh`: pulso cromatico que alterna o brilho do HUD.

## `:: o que esse setup entrega`

- HUD lateral/status com assinatura de operador e blocos de permissoes legiveis.
- `linemode = "size_and_mtime"` para listar tamanho e data com mais densidade.
- Sinais de `git` integrados no manager com estilo.
- Regras de abertura para texto, imagem, PDF, midia e arquivos compactados.
- Flavor `lain` combinado com overrides locais para empurrar o visual para o submundo synth.

```bash
ya pkg install
```

## `:: mapa do caos`

```text
.
├── init.lua        -> cerebro do HUD e linemode custom
├── yazi.toml       -> manager, openers, preview, fetchers
├── theme.toml      -> overrides de cor, icones e statusline
├── keymap.toml     -> atalhos locais
├── package.toml    -> plugins e flavor instalados
├── yazi-hud        -> launcher com moldura cyber terminal
└── hud_pulse.sh    -> animacao simples do pulso neon
```

## `:: estetica`

```text
╔══════════════════════════════════════════════════════════════╗
║ OPERATOR: braga.uss                                          ║
║ STATUS  : customizing the future one file at a time          ║
╚══════════════════════════════════════════════════════════════╝
```
