import gleam/int
import gleam/list
import sgleam/check

/// Representa o pesquisador preso no laboratório.
///
/// Campos:
/// - `nome`: nome do jogador.
/// - `inventario`: nomes dos itens coletados, sem repetições, na ordem
///   em que foram obtidos.
/// - `localizacao`: nome do ambiente em que o jogador está.
pub type Jogador {
  Jogador(
    nome: String,
    inventario: List(String),
    localizacao: String,
  )
}

/// Cria um jogador com inventário vazio e 100 pontos de vida,
/// posicionado em `localizacao`.
pub fn novo_jogador(nome: String, localizacao: String) -> Jogador {
  Jogador(
    nome: nome,
    inventario: [],
    localizacao: localizacao,
  )
}

/// Devolve True se `item` está no inventário (comparação exata).
/// Recursão estrutural sobre a lista.
pub fn tem_item(inventario: List(String), item: String) -> Bool {
  case inventario {
    [] -> False
    [primeiro, ..resto] -> primeiro == item || tem_item(resto, item)
  }
}

/// Devolve True se todos os `itens` estão no inventário.
/// Para a lista vazia de itens, devolve True.
pub fn possui_todos(inventario: List(String), itens: List(String)) -> Bool {
  case itens {
    [] -> True
    [item, ..resto] ->
      tem_item(inventario, item) && possui_todos(inventario, resto)
  }
}

/// Devolve, na ordem original, os itens de `itens` que NÃO estão no
/// inventário.
pub fn faltantes(inventario: List(String), itens: List(String)) -> List(String) {
  list.filter(itens, fn(item: String) { !tem_item(inventario, item) })
}

/// Devolve um novo jogador com `item` ao final do inventário.
/// Se o item já existe, devolve o jogador sem alterações.
pub fn adicionar_item(jogador: Jogador, item: String) -> Jogador {
  case tem_item(jogador.inventario, item) {
    True -> jogador
    False ->
      Jogador(
        ..jogador,
        inventario: list.append(jogador.inventario, [item]),
      )
  }
}

/// Devolve um novo jogador posicionado em `destino`.
pub fn mover(jogador: Jogador, destino: String) -> Jogador {
  Jogador(..jogador, localizacao: destino)
}

/// Conta os itens do inventário (recursão em cauda com acumulador).
pub fn contar_itens(inventario: List(String)) -> Int {
  contar_itens_loop(inventario, 0)
}

/// Auxiliar de `contar_itens`: `acc` é a quantidade já contada.
fn contar_itens_loop(inventario: List(String), acc: Int) -> Int {
  case inventario {
    [] -> acc
    [_, ..resto] -> contar_itens_loop(resto, acc + 1)
  }
}

/// Devolve o texto do inventário, numerando os itens a partir de 1.
/// Para inventário vazio, devolve "Inventário vazio.".
pub fn listar_inventario(inventario: List(String)) -> String {
  case inventario {
    [] -> "Inventário vazio."
    _ -> "Inventário:\n" <> enumerar(inventario, 1)
  }
}

/// Auxiliar de `listar_inventario`: numera `itens` começando em `n`,
/// uma linha por item.
fn enumerar(itens: List(String), n: Int) -> String {
  case itens {
    [] -> ""
    [item, ..resto] ->
      "  " <> int.to_string(n) <> ". " <> item <> "\n" <> enumerar(resto, n + 1)
  }
}

/// Testes de `novo_jogador`.
pub fn novo_jogador_examples() {
  check.eq(
    novo_jogador("Ana", "Recepção"),
    Jogador("Ana", [], "Recepção"),
  )
}

/// Testes de `tem_item` e `possui_todos`.
pub fn tem_item_examples() {
  check.eq(tem_item([], "Chave"), False)
  check.eq(tem_item(["Mapa", "Chave"], "Chave"), True)
  check.eq(tem_item(["Mapa"], "Chave"), False)
  check.eq(possui_todos(["A", "B", "C"], ["A", "C"]), True)
  check.eq(possui_todos(["A"], ["A", "C"]), False)
  check.eq(possui_todos(["A"], []), True)
}

/// Testes de `faltantes`.
pub fn faltantes_examples() {
  check.eq(faltantes(["A", "B"], ["A", "C", "D"]), ["C", "D"])
  check.eq(faltantes(["A"], ["A"]), [])
}

/// Testes de `adicionar_item` (inclui o caso de item repetido).
pub fn adicionar_item_examples() {
  let j = novo_jogador("Ana", "Recepção")
  let j1 = adicionar_item(j, "Nota Adesiva")
  check.eq(j1.inventario, ["Nota Adesiva"])
  check.eq(adicionar_item(j1, "Nota Adesiva"), j1)
  check.eq(adicionar_item(j1, "Rei de Copas").inventario, [
    "Nota Adesiva",
    "Rei de Copas",
  ])
  check.eq(j.inventario, [])
}

/// Testes de `mover`, `perder_vida` e `esta_vivo`.
pub fn movimento_examples() {
  let j = novo_jogador("Ana", "Recepção")
  check.eq(mover(j, "Auditoria").localizacao, "Auditoria")
}

/// Testes de `contar_itens`.
pub fn contar_itens_examples() {
  check.eq(contar_itens([]), 0)
  check.eq(contar_itens(["A", "B", "C"]), 3)
}

/// Testes de `listar_inventario`.
pub fn listar_inventario_examples() {
  check.eq(listar_inventario([]), "Inventário vazio.")
  check.eq(
    listar_inventario(["A", "B"]),
    "Inventário:\n  1. A\n  2. B\n",
  )
}
