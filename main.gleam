import gleam/io
import gleam/string
import menus
import sgleam/check

/// Texto de abertura da história com orientações de formatação.
pub fn introducao() -> String {
  "=== A SALA DOS DADOS VAZADOS ===\n"
  <> "Um laboratório de pesquisa detectou acesso indevido a documentos "
  <> "confidenciais e ativou o bloqueio automático de emergência. Você é "
  <> "um(a) pesquisador(a) preso(a) lá dentro. Explore 3 salas, colete 4 "
  <> "cartas de baralho, audite os registros e valide os dados autênticos "
  <> "para liberar a saída."
}

/// Exibe apenas a introdução, o menu de comandos e a sala inicial,
/// aguardando as chamadas interativas do jogador no terminal.
pub fn main() -> Nil {
  io.println(introducao())
  let _ = menus.iniciar("Pesquisador(a)")
  Nil
}

/// Testes de `introducao`.
pub fn introducao_examples() {
  check.eq(
    string.starts_with(introducao(), "=== A SALA DOS DADOS VAZADOS ==="),
    True,
  )
  check.eq(string.contains(introducao(), "3 salas"), True)
}
