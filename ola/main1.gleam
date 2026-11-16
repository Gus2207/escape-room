import gleam/io
import gleam/string
import jogo
import menus
import sgleam/check

/// Texto de abertura da história.
pub fn introducao() -> String {
  "=== A SALA DOS DADOS VAZADOS ===\n"
  <> "Um laboratório de pesquisa detectou acesso indevido a documentos "
  <> "confidenciais e ativou o bloqueio automático de emergência. Você é "
  <> "um(a) pesquisador(a) preso(a) lá dentro. Explore 3 salas, colete 4 "
  <> "cartas de baralho, audite os registros e valide os dados autênticos "
  <> "para liberar a saída."
}

/// Executa a demonstração: imprime a introdução e o menu e joga o
/// roteiro completo da fuga, imprimindo cada passo.
pub fn main() -> Nil {
  io.println(introducao())
  menus.display_main_menu()
  let estado = jogo.novo_jogo("Pesquisador(a)")
  let fim = menus.mostrar_roteiro(estado, menus.roteiro_fuga())
  io.println("\n" <> jogo.mensagem_final(fim))
}

/// Testes de `introducao`.
pub fn introducao_examples() {
  check.eq(string.starts_with(introducao(), "=== A SALA DOS DADOS VAZADOS"), True)
  check.eq(string.contains(introducao(), "3 salas"), True)
}
