import enigma.{type Enigma}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import jogador.{type Jogador}
import objeto.{type Objeto}
import sgleam/check

/// Nome da Recepção do Laboratório (sala inicial).
pub const nome_recepcao: String = "Recepção"

/// Nome da Sala de Auditoria e Monitoramento.
pub const nome_auditoria: String = "Auditoria"

/// Nome da Sala dos Servidores (Núcleo Central).
pub const nome_servidores: String = "Servidores"

/// Nome da passagem para fora do laboratório (saída final).
pub const nome_saida: String = "Saída"

/// Localização do jogador depois de escapar do laboratório.
pub const nome_fora: String = "Fora do Laboratório"

/// Um ambiente (sala) do laboratório.
///
/// Campos:
/// - `nome`: nome curto e único da sala.
/// - `descricao`: texto exibido ao explorar a sala.
/// - `objetos`: objetos ainda disponíveis na sala.
/// - `saidas`: nomes dos locais alcançáveis a partir da sala.
/// - `enigmas`: enigmas pendentes; o primeiro da lista é o atual.
pub type Ambiente {
  Ambiente(
    nome: String,
    descricao: String,
    objetos: List(Objeto),
    saidas: List(String),
    enigmas: List(Enigma),
  )
}

/// Devolve a lista unida por vírgulas, ou "nenhum" se estiver vazia.
fn lista_ou_nenhum(itens: List(String)) -> String {
  case itens {
    [] -> "nenhum"
    _ -> string.join(itens, ", ")
  }
}

/// Devolve o texto de exploração: descrição, objetos presentes e saídas.
pub fn explorar(ambiente: Ambiente, _jogador: Jogador) -> String {
  let objetos_txt = list.map(ambiente.objetos, fn(obj: Objeto) { obj.nome })
  let saidas_txt = list.map(ambiente.saidas, fn(s: String) { s })
  string.join(
    [
      ambiente.descricao,
      "Objetos: " <> lista_ou_nenhum(objetos_txt),
      "Saídas: " <> lista_ou_nenhum(saidas_txt),
    ],
    "\n",
  )
}

/// Devolve um novo ambiente sem o objeto de nome exato `nome`.
/// Se não existir, o conteúdo permanece igual.
pub fn remover_objeto(amb: Ambiente, nome: String) -> Ambiente {
  Ambiente(
    ..amb,
    objetos: list.filter(amb.objetos, fn(obj: Objeto) { obj.nome != nome }),
  )
}

/// Devolve o enigma pendente (o primeiro da lista), ou `None` se não
/// houver nenhum.
pub fn enigma_pendente(amb: Ambiente) -> Option(Enigma) {
  case amb.enigmas {
    [] -> None
    [primeiro, ..] -> Some(primeiro)
  }
}

/// Devolve um novo ambiente sem o enigma pendente (o primeiro). Se não
/// houver enigmas, devolve o ambiente sem alterações.
pub fn remover_enigma_resolvido(amb: Ambiente) -> Ambiente {
  case amb.enigmas {
    [] -> amb
    [_, ..resto] -> Ambiente(..amb, enigmas: resto)
  }
}

/// Procura um ambiente pelo nome exato.
pub fn buscar_ambiente(
  ambientes: List(Ambiente),
  nome: String,
) -> Option(Ambiente) {
  case ambientes {
    [] -> None
    [amb, ..resto] ->
      case amb.nome == nome {
        True -> Some(amb)
        False -> buscar_ambiente(resto, nome)
      }
  }
}

/// Devolve a lista com o ambiente de mesmo nome de `novo` trocado por
/// `novo`; os demais permanecem iguais.
pub fn substituir_ambiente(
  ambientes: List(Ambiente),
  novo: Ambiente,
) -> List(Ambiente) {
  list.map(ambientes, fn(amb: Ambiente) {
    case amb.nome == novo.nome {
      True -> novo
      False -> amb
    }
  })
}

/// Procura `destino` entre as saídas (comparação exata) e devolve
/// o nome da saída, ou `None` se não existir.
pub fn achar_saida(saidas: List(String), destino: String) -> Option(String) {
  case saidas {
    [] -> None
    [saida, ..resto] ->
      case saida == destino {
        True -> Some(saida)
        False -> achar_saida(resto, destino)
      }
  }
}

/// Sala 1: Recepção do Laboratório (Enigma 1: Cifra de César).
pub fn sala_recepcao() -> Ambiente {
  Ambiente(
    nome: nome_recepcao,
    descricao: "RECEPÇÃO DO LABORATÓRIO. As portas externas estão travadas por persianas de aço e o corredor interno exige uma senha no terminal de segurança. Uma luz vermelha de emergência pisca sobre a catraca.",
    objetos: [objeto.nota_adesiva(), objeto.rainha_de_ouros()],
    saidas: [nome_auditoria],
    enigmas: [enigma.enigma_cesar()],
  )
}

/// Sala 2: Sala de Auditoria e Monitoramento (Enigma 2).
pub fn sala_auditoria() -> Ambiente {
  Ambiente(
    nome: nome_auditoria,
    descricao: "SALA DE AUDITORIA E MONITORAMENTO. Telas exibem os registros de operação dos servidores. A porta blindada para o núcleo exige identificar os técnicos que violaram o protocolo de manutenção compartilhada.",
    objetos: [
      objeto.manual_de_protocolo(),
      objeto.trilha_de_auditoria(),
      objeto.rei_de_copas(),
      objeto.valete_de_espadas(),
    ],
    saidas: [nome_recepcao, nome_servidores],
    enigmas: [enigma.enigma_auditoria()],
  )
}

/// Sala 3: Sala dos Servidores, núcleo central (Enigma 3).
pub fn sala_servidores() -> Ambiente {
  Ambiente(
    nome: nome_servidores,
    descricao: "SALA DOS SERVIDORES (NÚCLEO CENTRAL). Fileiras de racks zumbem ao redor do painel de contenção, que controla o bloqueio do edifício e guarda os registros autênticos.",
    objetos: [objeto.as_de_paus(), objeto.placa_de_bronze()],
    saidas: [nome_auditoria, nome_saida],
    enigmas: [enigma.enigma_poema()],
  )
}

/// Testes de `explorar`.
pub fn explorar_examples() {
  let j = jogador.novo_jogador("Ana", nome_recepcao)
  check.eq(
    explorar(sala_recepcao(), j),
    sala_recepcao().descricao
      <> "\nObjetos: Nota Adesiva, Rainha de Ouros\nSaídas: Auditoria",
  )
  check.eq(
    explorar(Ambiente("Vazia", "Sala vazia.", [], [], []), j),
    "Sala vazia.\nObjetos: nenhum\nSaídas: nenhum",
  )
}

/// Testes de `remover_objeto`.
pub fn remover_objeto_examples() {
  let sala = sala_recepcao()
  check.eq(objeto.nomes(remover_objeto(sala, "Nota Adesiva").objetos), [
    "Rainha de Ouros",
  ])
  check.eq(objeto.nomes(remover_objeto(sala, "nota adesiva").objetos), [
    "Nota Adesiva",
    "Rainha de Ouros",
  ])
  check.eq(objeto.nomes(remover_objeto(sala, "Inexistente").objetos), [
    "Nota Adesiva",
    "Rainha de Ouros",
  ])
}

/// Testes de `enigma_pendente` e `remover_enigma_resolvido`.
pub fn enigmas_examples() {
  let sala = sala_recepcao()
  let resolvida = remover_enigma_resolvido(sala)
  check.eq(resolvida.enigmas, [])
  check.eq(remover_enigma_resolvido(resolvida).enigmas, [])
  check.eq(
    case enigma_pendente(sala) {
      Some(e) -> e.solucao
      None -> ""
    },
    "MAIN",
  )
  check.eq(
    case enigma_pendente(resolvida) {
      Some(e) -> e.solucao
      None -> ""
    },
    "",
  )
}

/// Nome do ambiente em um `Option(Ambiente)`, ou "" se `None`
/// (auxiliar dos testes).
fn nome_ou_vazio(opcional: Option(Ambiente)) -> String {
  case opcional {
    Some(amb) -> amb.nome
    None -> ""
  }
}

/// Testes de `buscar_ambiente` e `substituir_ambiente`.
pub fn buscar_e_substituir_examples() {
  let todos = [sala_recepcao(), sala_auditoria(), sala_servidores()]
  check.eq(nome_ou_vazio(buscar_ambiente([], "Recepção")), "")
  check.eq(nome_ou_vazio(buscar_ambiente(todos, "Servidores")), "Servidores")
  check.eq(nome_ou_vazio(buscar_ambiente(todos, "servidores")), "")
  check.eq(nome_ou_vazio(buscar_ambiente(todos, "Cozinha")), "")
  let nova = Ambiente(..sala_auditoria(), objetos: [])
  let atualizados = substituir_ambiente(todos, nova)
  check.eq(
    case buscar_ambiente(atualizados, "Auditoria") {
      Some(amb) -> amb.objetos
      None -> [objeto.nota_adesiva()]
    },
    [],
  )
  check.eq(
    list.map(atualizados, fn(amb: Ambiente) { amb.nome }),
    ["Recepção", "Auditoria", "Servidores"],
  )
}

/// Testes de `achar_saida`.
pub fn achar_saida_examples() {
  check.eq(achar_saida([], "Saída"), None)
  check.eq(achar_saida(["Auditoria", "Saída"], "Saída"), Some("Saída"))
  check.eq(achar_saida(["Auditoria", "Saída"], "saida"), None)
  check.eq(achar_saida(["Auditoria"], "Servidores"), None)
}

/// Testes das salas da história.
pub fn salas_examples() {
  check.eq(sala_recepcao().saidas, ["Auditoria"])
  check.eq(sala_auditoria().saidas, ["Recepção", "Servidores"])
  check.eq(sala_servidores().saidas, ["Auditoria", "Saída"])
  check.eq(objeto.nomes(sala_auditoria().objetos), [
    "Manual de Protocolo",
    "Trilha de Auditoria",
    "Rei de Copas",
    "Valete de Espadas",
  ])
}
