import gleam/list
import gleam/option.{type Option, None, Some}
import jogador.{type Jogador}
import sgleam/check

/// Objeto que pode ser examinado ou coletado em um ambiente.
///
/// Campos:
/// - `nome`: nome único do objeto no ambiente.
/// - `descricao`: texto mostrado ao jogador ao examinar o objeto.
/// - `interacao`: função pura que recebe o jogador e devolve o jogador
///   atualizado após interagir com o objeto.
/// - `estado`: "coletavel" (vai para o inventário) ou "leitura"
///   (apenas exibe a descrição).
pub type Objeto {
  Objeto(
    nome: String,
    descricao: String,
    interacao: fn(Jogador) -> Jogador,
    estado: String,
  )
}

/// Cria um objeto coletável: ao interagir, seu nome é adicionado ao
/// inventário do jogador (sem duplicar).
pub fn objeto_coletavel(nome: String, descricao: String) -> Objeto {
  Objeto(
    nome: nome,
    descricao: descricao,
    interacao: fn(j: Jogador) { jogador.adicionar_item(j, nome) },
    estado: "coletavel",
  )
}

/// Cria um objeto de leitura: a interação não altera o jogador.
pub fn objeto_leitura(nome: String, texto_lido: String) -> Objeto {
  Objeto(
    nome: nome,
    descricao: texto_lido,
    interacao: fn(j: Jogador) { j },
    estado: "leitura",
  )
}

/// Aplica a interação do objeto ao jogador e devolve o novo jogador.
pub fn interagir(objeto: Objeto, jogador: Jogador) -> Jogador {
  objeto.interacao(jogador)
}

/// Devolve os nomes dos objetos, na mesma ordem.
pub fn nomes(objetos: List(Objeto)) -> List(String) {
  list.map(objetos, fn(obj: Objeto) { obj.nome })
}

/// Procura um objeto pelo nome exato (respeitando maiúsculas, minúsculas
/// e acentos). Devolve `None` se não existir.
pub fn buscar_objeto(objetos: List(Objeto), nome: String) -> Option(Objeto) {
  case objetos {
    [] -> None
    [obj, ..resto] ->
      case obj.nome == nome {
        True -> Some(obj)
        False -> buscar_objeto(resto, nome)
      }
  }
}

/// Nota adesiva com a senha cifrada (coletável).
pub fn nota_adesiva() -> Objeto {
  objeto_coletavel(
    "Nota Adesiva",
    "Código de acesso: PDLQ. Lembrete do TI: dê 3 passos para trás no alfabeto.",
  )
}

/// Carta caída perto da catraca (coletável).
pub fn rainha_de_ouros() -> Objeto {
  objeto_coletavel(
    "Rainha de Ouros",
    "Uma carta de baralho caída perto da catraca: a Rainha de Ouros.",
  )
}

/// Manual com as quatro regras de manutenção compartilhada (leitura).
pub fn manual_de_protocolo() -> Objeto {
  objeto_leitura(
    "Manual de Protocolo",
    "MANUAL DE PROTOCOLO DE MANUTENÇÃO COMPARTILHADA\n"
      <> "Regra 01: Desconectar os servidores da rede externa antes de qualquer intervenção na segurança ou no sistema.\n"
      <> "Regra 02: Desativar o sistema de segurança somente após os servidores estarem desconectados da rede.\n"
      <> "Regra 03: Executar atualizações de sistema/módulos apenas com o sistema de segurança desativado e a rede desconectada.\n"
      <> "Regra 04: Ao concluir uma manutenção, reativar o sistema de segurança e reconectar a rede antes de encerrar o ciclo.",
  )
}

/// Registro cronológico das intervenções nos servidores (leitura).
pub fn trilha_de_auditoria() -> Objeto {
  objeto_leitura(
    "Trilha de Auditoria",
    "TRILHA DE AUDITORIA (estado inicial às 08:00: Rede Conectada | Segurança Ativa)\n"
      <> "08:15 - Carlos: Desconectou os servidores da rede e iniciou a preparação dos arquivos.\n"
      <> "09:30 - Mariana: Verificou o status, desativou o sistema de segurança e atualizou o banco de dados. Ao finalizar, reativou a segurança e reconectou a rede.\n"
      <> "11:10 - Rafael: Chegou ao terminal, desativou o sistema de segurança e atualizou o kernel.\n"
      <> "13:45 - Beatriz: Percebeu o alerta, desconectou os servidores da rede, concluiu a atualização do kernel, reativou a segurança e reconectou a rede.\n"
      <> "15:20 - Thiago: Desconectou os servidores da rede e atualizou o módulo de firewall.\n"
      <> "17:00 - Fernanda: Checou o painel, desativou a segurança, finalizou os patches do firewall, mas apenas reconectou a rede antes de ir embora.",
  )
}

/// Carta guardada em uma pasta de arquivos fictícios (coletável).
pub fn rei_de_copas() -> Objeto {
  objeto_coletavel(
    "Rei de Copas",
    "Uma carta de baralho guardada em uma pasta de arquivos fictícios: o Rei de Copas.",
  )
}

/// Carta guardada em uma pasta de arquivos fictícios (coletável).
pub fn valete_de_espadas() -> Objeto {
  objeto_coletavel(
    "Valete de Espadas",
    "Uma carta de baralho guardada em uma pasta de arquivos fictícios: o Valete de Espadas.",
  )
}

/// Carta sobre o rack principal (coletável).
pub fn as_de_paus() -> Objeto {
  objeto_coletavel(
    "Ás de Paus",
    "Uma carta de baralho sobre o rack principal: o Ás de Paus.",
  )
}

/// Placa com o poema que ordena as figuras das cartas (leitura).
pub fn placa_de_bronze() -> Objeto {
  objeto_leitura(
    "Placa de Bronze",
    "Cega pelo brilho do ouro e da coroa,\n"
      <> "A RAINHA partiu, deixando o reino à toa.\n"
      <> "Com o coração partido e o futuro escuro,\n"
      <> "Caiu o REI, um homem leal e puro.\n"
      <> "Mas logo à espreita, o VALETE preparou a emboscada,\n"
      <> "Um falso cavaleiro empunhando a sua espada.\n"
      <> "Para usurpar o trono e a glória conquistar,\n"
      <> "Tinha um ÁS na manga para o golpe final dar.",
  )
}

/// Testes de `objeto_coletavel` e `interagir`.
pub fn coletavel_examples() {
  let j = jogador.novo_jogador("Ana", "Recepção")
  let obj = rainha_de_ouros()
  check.eq(obj.nome, "Rainha de Ouros")
  check.eq(obj.estado, "coletavel")
  check.eq(interagir(obj, j).inventario, ["Rainha de Ouros"])
  check.eq(interagir(obj, interagir(obj, j)).inventario, ["Rainha de Ouros"])
}

/// Testes de `objeto_leitura` e `interagir`.
pub fn leitura_examples() {
  let j = jogador.novo_jogador("Ana", "Auditoria")
  let obj = objeto_leitura("Aviso", "Texto do aviso.")
  check.eq(obj.estado, "leitura")
  check.eq(interagir(obj, j), j)
  check.eq(obj.descricao, "Texto do aviso.")
}

/// Testes de `nomes`.
pub fn nomes_examples() {
  check.eq(nomes([]), [])
  check.eq(nomes([nota_adesiva(), rainha_de_ouros()]), [
    "Nota Adesiva",
    "Rainha de Ouros",
  ])
}

/// Extrai o nome de um `Option(Objeto)` ("" se for `None`); auxiliar dos testes.
fn nome_ou_vazio(opcional: Option(Objeto)) -> String {
  case opcional {
    Some(obj) -> obj.nome
    None -> ""
  }
}

/// Testes de `buscar_objeto` (lista vazia, achado exato e grafia incorreta).
pub fn buscar_objeto_examples() {
  let objetos = [nota_adesiva(), rainha_de_ouros()]
  check.eq(nome_ou_vazio(buscar_objeto([], "Nota Adesiva")), "")
  check.eq(nome_ou_vazio(buscar_objeto(objetos, "Nota Adesiva")), "Nota Adesiva")
  check.eq(
    nome_ou_vazio(buscar_objeto(objetos, "Rainha de Ouros")),
    "Rainha de Ouros",
  )
  check.eq(nome_ou_vazio(buscar_objeto(objetos, "nota adesiva")), "")
  check.eq(nome_ou_vazio(buscar_objeto(objetos, "Rei de Copas")), "")
}

/// Testes dos objetos da história.
pub fn objetos_da_historia_examples() {
  check.eq(nota_adesiva().estado, "coletavel")
  check.eq(rei_de_copas().estado, "coletavel")
  check.eq(valete_de_espadas().estado, "coletavel")
  check.eq(as_de_paus().estado, "coletavel")
  check.eq(manual_de_protocolo().estado, "leitura")
  check.eq(trilha_de_auditoria().estado, "leitura")
  check.eq(placa_de_bronze().estado, "leitura")
}
