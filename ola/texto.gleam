import gleam/list
import gleam/string
import sgleam/check

/// Pares (letra acentuada, letra sem acento) usados na normalização.
fn substituicoes() -> List(#(String, String)) {
  [
    #("Á", "A"),
    #("À", "A"),
    #("Â", "A"),
    #("Ã", "A"),
    #("É", "E"),
    #("Ê", "E"),
    #("Í", "I"),
    #("Ó", "O"),
    #("Ô", "O"),
    #("Õ", "O"),
    #("Ú", "U"),
    #("Ç", "C"),
  ]
}

/// Normaliza um texto para comparação: remove espaços nas pontas,
/// converte para maiúsculas e troca letras acentuadas pelas equivalentes
/// sem acento. A saída nunca contém letras minúsculas.
pub fn normalizar(texto: String) -> String {
  list.fold(
    substituicoes(),
    string.uppercase(string.trim(texto)),
    fn(acc: String, par: #(String, String)) { string.replace(acc, par.0, par.1) },
  )
}

/// Devolve True se os dois textos são iguais após a normalização
/// (ignora maiúsculas/minúsculas, acentos e espaços nas pontas).
pub fn iguais(a: String, b: String) -> Bool {
  normalizar(a) == normalizar(b)
}

/// Devolve True se `item` aparece em `itens`, comparando com `iguais`.
/// Recursão estrutural sobre a lista.
pub fn pertence(itens: List(String), item: String) -> Bool {
  case itens {
    [] -> False
    [primeiro, ..resto] -> iguais(primeiro, item) || pertence(resto, item)
  }
}

/// Testes de `normalizar`.
pub fn normalizar_examples() {
  check.eq(normalizar("  rainha "), "RAINHA")
  check.eq(normalizar("Ás de Paus"), "AS DE PAUS")
  check.eq(normalizar("Recepção"), "RECEPCAO")
  check.eq(normalizar(""), "")
}

/// Testes de `iguais`.
pub fn iguais_examples() {
  check.eq(iguais("main", " MAIN "), True)
  check.eq(iguais("Saída", "saida"), True)
  check.eq(iguais("REI", "RAINHA"), False)
}

/// Testes de `pertence` (caso base e caso recursivo).
pub fn pertence_examples() {
  check.eq(pertence([], "a"), False)
  check.eq(pertence(["Recepção", "Auditoria"], "auditoria"), True)
  check.eq(pertence(["Recepção", "Auditoria"], "Servidores"), False)
}
