import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import jogador.{type Jogador}
import sgleam/check
import texto

/// Nome do item concedido pelo Enigma 1 (libera a Sala de Auditoria).
pub const cartao_nivel_1: String = "Cartão de Acesso Nível 1"

/// Nome do item concedido pelo Enigma 2 (libera a Sala dos Servidores).
pub const cartao_nivel_2: String = "Cartão de Acesso Nível 2"

/// Nome do item concedido pelo Enigma 3; sua posse desativa o bloqueio.
pub const item_registro: String = "Registro Autêntico (Dados Recuperados)"

/// Enigma proposto ao jogador em um ambiente.
///
/// Campos:
/// - `descricao`: enunciado do desafio.
/// - `solucao`: resposta esperada (comparada sem distinguir maiúsculas
///   nem acentos).
/// - `pistas`: dicas em ordem crescente de ajuda.
/// - `requisitos`: itens que o jogador precisa ter para tentar resolver.
/// - `mensagem_sucesso`: texto exibido quando o enigma é resolvido.
/// - `efeito`: função pura aplicada ao jogador quando a resposta está certa.
pub type Enigma {
  Enigma(
    descricao: String,
    solucao: String,
    pistas: List(String),
    requisitos: List(String),
    mensagem_sucesso: String,
    efeito: fn(Jogador) -> Jogador,
  )
}

/// Motivos pelos quais uma tentativa de resolver um enigma falha.
///
/// - `RequisitosAusentes(itens)`: faltam esses itens no inventário.
/// - `RespostaIncorreta`: a resposta não confere com a solução.
pub type ErroEnigma {
  RequisitosAusentes(List(String))
  RespostaIncorreta
}

/// Aplica o efeito do enigma se `resposta` confere com a solução; caso
/// contrário devolve o jogador sem alterações. Não verifica requisitos.
pub fn resolver_enigma(
  enigma: Enigma,
  resposta: String,
  jogador: Jogador,
) -> Jogador {
  case texto.iguais(resposta, enigma.solucao) {
    True -> enigma.efeito(jogador)
    False -> jogador
  }
}

/// Tenta resolver o enigma. Devolve `Ok(novo_jogador)` se o jogador
/// possui os requisitos e a resposta está correta, ou `Error(motivo)`.
/// Os requisitos são verificados antes da resposta.
pub fn tentar_resolver(
  enigma: Enigma,
  resposta: String,
  jog: Jogador,
) -> Result(Jogador, ErroEnigma) {
  verificar_requisitos(enigma, jog)
  |> result.try(fn(_) { verificar_resposta(enigma, resposta) })
  |> result.try(fn(_) { Ok(enigma.efeito(jog)) })
}

/// Devolve `Ok(Nil)` se o jogador tem todos os requisitos do enigma, ou
/// `Error(RequisitosAusentes(faltantes))`.
fn verificar_requisitos(enigma: Enigma, jog: Jogador) -> Result(Nil, ErroEnigma) {
  case jogador.faltantes(jog.inventario, enigma.requisitos) {
    [] -> Ok(Nil)
    faltantes -> Error(RequisitosAusentes(faltantes))
  }
}

/// Devolve `Ok(Nil)` se a resposta confere com a solução, ou
/// `Error(RespostaIncorreta)`.
fn verificar_resposta(enigma: Enigma, resposta: String) -> Result(Nil, ErroEnigma) {
  case texto.iguais(resposta, enigma.solucao) {
    True -> Ok(Nil)
    False -> Error(RespostaIncorreta)
  }
}

/// Devolve a `n`-ésima pista (contagem a partir de 1), ou `None` se `n`
/// for menor que 1 ou maior que a quantidade de pistas.
/// Recursão simultânea sobre a lista e sobre o número.
pub fn pista_n(pistas: List(String), n: Int) -> Option(String) {
  case pistas, n {
    [primeira, ..], 1 -> Some(primeira)
    [_, ..resto], _ if n > 1 -> pista_n(resto, n - 1)
    _, _ -> None
  }
}

/// Enigma 1 (Cifra de César): recuar 3 letras em "PDLQ".
pub fn enigma_cesar() -> Enigma {
  Enigma(
    descricao: "O terminal de acesso ao corredor pede uma senha de 4 letras. Use a nota adesiva: retroceda 3 letras no alfabeto em cada letra do código.",
    solucao: "MAIN",
    pistas: [
      "A Nota Adesiva da recepção traz um código de 4 letras.",
      "O lembrete do TI manda dar 3 passos para trás no alfabeto.",
      "Retroceder 3 letras: o P vira M. Faça o mesmo com D, L e Q.",
    ],
    requisitos: [],
    mensagem_sucesso: "Acesso concedido! O terminal libera o corredor e emite o "
      <> cartao_nivel_1
      <> ". A Sala de Auditoria agora está acessível.",
    efeito: fn(j: Jogador) { jogador.adicionar_item(j, cartao_nivel_1) },
  )
}

/// Enigma 2 (Auditoria de Manutenção Compartilhada): os três infratores
/// em ordem cronológica, cada um seguido do número da regra violada.
pub fn enigma_auditoria() -> Enigma {
  Enigma(
    descricao: "A porta blindada exige os 3 técnicos que violaram o protocolo, em ordem cronológica, no formato NOME REGRA separados por vírgula.",
    solucao: "RAFAEL 02, THIAGO 03, FERNANDA 04",
    pistas: [
      "Compare cada ação da Trilha de Auditoria com as regras do Manual de Protocolo.",
      "Acompanhe o estado (rede e segurança) depois de cada técnico: ele é o ponto de partida do próximo.",
      "Três técnicos violaram regras diferentes. Responda como: NOME 00, NOME 00, NOME 00.",
    ],
    requisitos: [],
    mensagem_sucesso: "Infratores confirmados! A porta blindada emite o "
      <> cartao_nivel_2
      <> ". A Sala dos Servidores agora está acessível.",
    efeito: fn(j: Jogador) { jogador.adicionar_item(j, cartao_nivel_2) },
  )
}

/// Enigma 3 (O Poema das Cartas): as quatro figuras na ordem do poema.
/// Exige as quatro cartas coletadas.
pub fn enigma_poema() -> Enigma {
  Enigma(
    descricao: "O painel de contenção pede a sequência das 4 figuras das cartas coletadas, na ordem em que aparecem na Placa de Bronze (separadas por espaço).",
    solucao: "RAINHA REI VALETE AS",
    pistas: [
      "Na Placa de Bronze, cada figura aparece em letras maiúsculas.",
      "A ordem correta é a do poema, não a da coleta.",
      "O Ás pode ser escrito como AS.",
    ],
    requisitos: cartas_necessarias(),
    mensagem_sucesso: "Registros autênticos recuperados! O bloqueio de emergência foi desativado e a saída do laboratório está liberada.",
    efeito: fn(j: Jogador) { jogador.adicionar_item(j, item_registro) },
  )
}

/// As quatro cartas que o jogador precisa ter para tentar o Enigma 3.
pub fn cartas_necessarias() -> List(String) {
  ["Rainha de Ouros", "Rei de Copas", "Valete de Espadas", "Ás de Paus"]
}

// ---------------------------------------------------------------------
// Lógica da Trilha de Auditoria (Enigma 2)
// ---------------------------------------------------------------------

/// Estado dos servidores durante a manutenção.
///
/// Campos:
/// - `rede_conectada`: True se os servidores estão ligados à rede externa.
/// - `seguranca_ativa`: True se o sistema de segurança está ativo.
pub type EstadoSistema {
  EstadoSistema(rede_conectada: Bool, seguranca_ativa: Bool)
}

/// Ações que um técnico pode executar. `VerificarStatus` e
/// `PrepararArquivos` não alteram o estado nem violam regras.
pub type AcaoTecnica {
  DesconectarRede
  ReconectarRede
  DesativarSeguranca
  ReativarSeguranca
  AtualizarSistema
  VerificarStatus
  PrepararArquivos
}

/// Intervenção de um técnico: horário, nome e ações em ordem.
///
/// Campos: `hora` ("HH:MM"), `tecnico` (nome) e `acoes` (sequência).
pub type Registro {
  Registro(hora: String, tecnico: String, acoes: List(AcaoTecnica))
}

/// Estado às 08:00: rede conectada e segurança ativa.
pub fn estado_inicial() -> EstadoSistema {
  EstadoSistema(rede_conectada: True, seguranca_ativa: True)
}

/// Devolve o novo estado depois de executar `acao` (função total: toda
/// ação é aplicada, mesmo que viole uma regra).
pub fn aplicar(estado: EstadoSistema, acao: AcaoTecnica) -> EstadoSistema {
  case acao {
    DesconectarRede -> EstadoSistema(..estado, rede_conectada: False)
    ReconectarRede -> EstadoSistema(..estado, rede_conectada: True)
    DesativarSeguranca -> EstadoSistema(..estado, seguranca_ativa: False)
    ReativarSeguranca -> EstadoSistema(..estado, seguranca_ativa: True)
    AtualizarSistema -> estado
    VerificarStatus -> estado
    PrepararArquivos -> estado
  }
}

/// Devolve `Some(numero_da_regra)` se executar `acao` no `estado` viola
/// uma regra do manual (2, 3 ou 4); caso contrário, `None`.
pub fn regra_violada(estado: EstadoSistema, acao: AcaoTecnica) -> Option(Int) {
  case acao {
    DesativarSeguranca if estado.rede_conectada -> Some(2)
    AtualizarSistema if estado.rede_conectada || estado.seguranca_ativa ->
      Some(3)
    ReconectarRede if !estado.seguranca_ativa -> Some(4)
    _ -> None
  }
}

/// Executa as ações em ordem a partir de `estado`. Devolve o estado final
/// e a PRIMEIRA violação ocorrida (`violacao` é a violação já encontrada;
/// comece com `None`).
pub fn processar_acoes(
  acoes: List(AcaoTecnica),
  estado: EstadoSistema,
  violacao: Option(Int),
) -> #(EstadoSistema, Option(Int)) {
  case acoes {
    [] -> #(estado, violacao)
    [acao, ..resto] -> {
      let nova_violacao = case violacao {
        None -> regra_violada(estado, acao)
        Some(_) -> violacao
      }
      processar_acoes(resto, aplicar(estado, acao), nova_violacao)
    }
  }
}

/// Audita os registros em ordem cronológica a partir de `estado` e
/// devolve, também em ordem cronológica, pares (técnico, regra violada)
/// apenas dos técnicos que violaram alguma regra.
pub fn auditar(
  registros: List(Registro),
  estado: EstadoSistema,
) -> List(#(String, Int)) {
  auditar_loop(registros, estado, [])
}

/// Auxiliar de `auditar` (recursão em cauda): `acc` guarda as infrações
/// encontradas, da mais recente para a mais antiga.
fn auditar_loop(
  registros: List(Registro),
  estado: EstadoSistema,
  acc: List(#(String, Int)),
) -> List(#(String, Int)) {
  case registros {
    [] -> list.reverse(acc)
    [Registro(_, tecnico, acoes), ..resto] -> {
      let #(novo_estado, violacao) = processar_acoes(acoes, estado, None)
      let novo_acc = case violacao {
        Some(regra) -> [#(tecnico, regra), ..acc]
        None -> acc
      }
      auditar_loop(resto, novo_estado, novo_acc)
    }
  }
}

/// Formata o número de uma regra com dois dígitos (1 vira "01").
/// Aceita valores de 0 a 99.
pub fn formatar_regra(regra: Int) -> String {
  case regra < 10 {
    True -> "0" <> int.to_string(regra)
    False -> int.to_string(regra)
  }
}

/// Formata as infrações como "NOME REGRA, NOME REGRA, ..." com os nomes
/// em maiúsculas. Para lista vazia, devolve "".
pub fn formatar_infracoes(infracoes: List(#(String, Int))) -> String {
  infracoes
  |> list.map(fn(i: #(String, Int)) {
    string.uppercase(i.0) <> " " <> formatar_regra(i.1)
  })
  |> string.join(", ")
}

/// Os seis registros da Trilha de Auditoria, em ordem cronológica.
pub fn trilha_registros() -> List(Registro) {
  [
    Registro("08:15", "Carlos", [DesconectarRede, PrepararArquivos]),
    Registro("09:30", "Mariana", [
      VerificarStatus,
      DesativarSeguranca,
      AtualizarSistema,
      ReativarSeguranca,
      ReconectarRede,
    ]),
    Registro("11:10", "Rafael", [DesativarSeguranca, AtualizarSistema]),
    Registro("13:45", "Beatriz", [
      DesconectarRede,
      AtualizarSistema,
      ReativarSeguranca,
      ReconectarRede,
    ]),
    Registro("15:20", "Thiago", [DesconectarRede, AtualizarSistema]),
    Registro("17:00", "Fernanda", [
      VerificarStatus,
      DesativarSeguranca,
      AtualizarSistema,
      ReconectarRede,
    ]),
  ]
}

// ---------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------

/// Testes de `resolver_enigma` (resposta certa e errada).
pub fn resolver_enigma_examples() {
  let j = jogador.novo_jogador("Ana", "Recepção")
  check.eq(resolver_enigma(enigma_cesar(), "main", j).inventario, [
    cartao_nivel_1,
  ])
  check.eq(resolver_enigma(enigma_cesar(), "PDLQ", j), j)
}

/// Testes de `tentar_resolver`: sucesso, erro de resposta e requisitos.
pub fn tentar_resolver_examples() {
  let j = jogador.novo_jogador("Ana", "Servidores")
  check.eq(
    tentar_resolver(enigma_cesar(), "MAIN", j),
    Ok(jogador.adicionar_item(j, cartao_nivel_1)),
  )
  check.eq(
    tentar_resolver(enigma_cesar(), "ABCD", j),
    Error(RespostaIncorreta),
  )
  check.eq(
    tentar_resolver(enigma_poema(), "RAINHA REI VALETE AS", j),
    Error(RequisitosAusentes(cartas_necessarias())),
  )
  let com_cartas =
    list.fold(cartas_necessarias(), j, fn(acc: Jogador, carta: String) {
      jogador.adicionar_item(acc, carta)
    })
  check.eq(
    tentar_resolver(enigma_poema(), "rainha rei valete ás", com_cartas),
    Ok(jogador.adicionar_item(com_cartas, item_registro)),
  )
  check.eq(
    tentar_resolver(enigma_poema(), "REI RAINHA VALETE AS", com_cartas),
    Error(RespostaIncorreta),
  )
}

/// Testes de `pista_n` (casos base e recursivo).
pub fn pista_n_examples() {
  check.eq(pista_n([], 1), None)
  check.eq(pista_n(["a", "b", "c"], 1), Some("a"))
  check.eq(pista_n(["a", "b", "c"], 3), Some("c"))
  check.eq(pista_n(["a", "b", "c"], 4), None)
  check.eq(pista_n(["a", "b", "c"], 0), None)
}

/// Testes dos efeitos dos três enigmas.
pub fn efeitos_examples() {
  let j = jogador.novo_jogador("Ana", "Recepção")
  check.eq((enigma_cesar().efeito)(j).inventario, [cartao_nivel_1])
  check.eq((enigma_auditoria().efeito)(j).inventario, [cartao_nivel_2])
  check.eq((enigma_poema().efeito)(j).inventario, [item_registro])
  check.eq(enigma_cesar().solucao, "MAIN")
}

/// Testes de `aplicar` (todas as variantes de `AcaoTecnica`).
pub fn aplicar_examples() {
  let s = estado_inicial()
  check.eq(aplicar(s, DesconectarRede), EstadoSistema(False, True))
  check.eq(aplicar(s, DesativarSeguranca), EstadoSistema(True, False))
  check.eq(
    aplicar(EstadoSistema(False, False), ReconectarRede),
    EstadoSistema(True, False),
  )
  check.eq(
    aplicar(EstadoSistema(False, False), ReativarSeguranca),
    EstadoSistema(False, True),
  )
  check.eq(aplicar(s, AtualizarSistema), s)
  check.eq(aplicar(s, VerificarStatus), s)
  check.eq(aplicar(s, PrepararArquivos), s)
}

/// Testes de `regra_violada` (regras 2, 3 e 4 e ações válidas).
pub fn regra_violada_examples() {
  check.eq(regra_violada(EstadoSistema(True, True), DesativarSeguranca), Some(2))
  check.eq(regra_violada(EstadoSistema(False, True), DesativarSeguranca), None)
  check.eq(regra_violada(EstadoSistema(False, True), AtualizarSistema), Some(3))
  check.eq(regra_violada(EstadoSistema(True, False), AtualizarSistema), Some(3))
  check.eq(regra_violada(EstadoSistema(False, False), AtualizarSistema), None)
  check.eq(regra_violada(EstadoSistema(False, False), ReconectarRede), Some(4))
  check.eq(regra_violada(EstadoSistema(False, True), ReconectarRede), None)
  check.eq(regra_violada(estado_inicial(), VerificarStatus), None)
}

/// Testes de `processar_acoes`.
pub fn processar_acoes_examples() {
  check.eq(processar_acoes([], estado_inicial(), None), #(
    estado_inicial(),
    None,
  ))
  check.eq(
    processar_acoes(
      [DesativarSeguranca, AtualizarSistema],
      estado_inicial(),
      None,
    ),
    #(EstadoSistema(True, False), Some(2)),
  )
  check.eq(
    processar_acoes([DesconectarRede, PrepararArquivos], estado_inicial(), None),
    #(EstadoSistema(False, True), None),
  )
}

/// Testes de `auditar` e da integração com a solução do Enigma 2.
pub fn auditar_examples() {
  check.eq(auditar([], estado_inicial()), [])
  check.eq(auditar(trilha_registros(), estado_inicial()), [
    #("Rafael", 2),
    #("Thiago", 3),
    #("Fernanda", 4),
  ])
  check.eq(
    formatar_infracoes(auditar(trilha_registros(), estado_inicial())),
    enigma_auditoria().solucao,
  )
}

/// Testes de `formatar_regra` e `formatar_infracoes`.
pub fn formatacao_examples() {
  check.eq(formatar_regra(2), "02")
  check.eq(formatar_regra(12), "12")
  check.eq(formatar_infracoes([]), "")
  check.eq(formatar_infracoes([#("Ana", 3)]), "ANA 03")
}
