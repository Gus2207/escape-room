import gleam/int
import gleam/io
import gleam/list
import gleam/string
import jogador
import jogo.{type Jogo, EmAndamento, Fugiu}
import sgleam/check

/// Opções do menu principal.
///
/// - `Explorar`: descreve a sala atual.
/// - `Inventario`: mostra itens e pontos de vida.
/// - `Enigmas`: mostra o enigma pendente da sala.
/// - `Interagir(nome)`: interage com o objeto `nome`.
/// - `Resolver(resposta)`: tenta resolver o enigma da sala.
/// - `IrPara(destino)`: move o jogador para outra sala.
/// - `PedirDica(n)`: mostra a n-ésima pista do enigma da sala.
/// - `Sair`: encerra a simulação.
pub type MainMenu {
  Explorar
  Inventario
  Enigmas
  Interagir(String)
  Resolver(String)
  IrPara(String)
  PedirDica(Int)
  Sair
}

/// Exibe o menu principal no terminal (camada de apresentação).
pub fn display_main_menu() -> Nil {
  io.println("--- MENU PRINCIPAL ---")
  io.println("m1(): Explorar ambiente")
  io.println("m2(): Consultar inventário")
  io.println("m3(): Examinar enigmas")
  io.println("m4(\"objeto\"): Interagir com um objeto")
  io.println("m5(\"resposta\"): Resolver o enigma da sala")
  io.println("m6(\"destino\"): Ir para outra sala")
  io.println("m7(n): Pedir a n-ésima pista")
  io.println("exit(): Encerrar simulação")
}

/// Opção "Explorar ambiente".
pub fn m1() -> MainMenu {
  Explorar
}

/// Opção "Consultar inventário".
pub fn m2() -> MainMenu {
  Inventario
}

/// Opção "Examinar enigmas".
pub fn m3() -> MainMenu {
  Enigmas
}

/// Opção "Interagir com o objeto `nome_objeto`".
pub fn m4(nome_objeto: String) -> MainMenu {
  Interagir(nome_objeto)
}

/// Opção "Resolver o enigma da sala com `resposta`".
pub fn m5(resposta: String) -> MainMenu {
  Resolver(resposta)
}

/// Opção "Ir para `destino`".
pub fn m6(destino: String) -> MainMenu {
  IrPara(destino)
}

/// Opção "Pedir a pista número `n`" (a partir de 1).
pub fn m7(n: Int) -> MainMenu {
  PedirDica(n)
}

/// Opção "Encerrar simulação".
pub fn exit() -> MainMenu {
  Sair
}

/// Executa uma opção do menu sobre o estado e devolve o novo estado e a
/// mensagem resultante. É pura: não imprime nada. Depois que o jogo
/// termina (fuga ou derrota), só `Sair` é aceita.
pub fn executar(estado: Jogo, opcao: MainMenu) -> #(Jogo, String) {
  case jogo.situacao(estado), opcao {
    EmAndamento, Explorar -> jogo.explorar_sala(estado)
    EmAndamento, Inventario -> jogo.consultar_inventario(estado)
    EmAndamento, Enigmas -> jogo.examinar_enigmas(estado)
    EmAndamento, Interagir(nome) -> jogo.interagir_objeto(estado, nome)
    EmAndamento, Resolver(resposta) -> jogo.resolver(estado, resposta)
    EmAndamento, IrPara(destino) -> jogo.mover_para(estado, destino)
    EmAndamento, PedirDica(n) -> jogo.pedir_dica(estado, n)
    _, Sair -> #(estado, "Simulação encerrada.")
    _, _ -> #(estado, "A simulação já terminou. " <> jogo.mensagem_final(estado))
  }
}

/// Aplica uma lista de opções em sequência e devolve o estado final
/// (usa `list.fold`).
pub fn executar_roteiro(estado: Jogo, opcoes: List(MainMenu)) -> Jogo {
  list.fold(opcoes, estado, fn(acc: Jogo, opcao: MainMenu) {
    executar(acc, opcao).0
  })
}

/// Devolve o texto da chamada de menu equivalente à opção, por exemplo
/// `m4("Nota Adesiva")`.
pub fn descrever_opcao(opcao: MainMenu) -> String {
  case opcao {
    Explorar -> "m1()"
    Inventario -> "m2()"
    Enigmas -> "m3()"
    Interagir(nome) -> "m4(\"" <> nome <> "\")"
    Resolver(resposta) -> "m5(\"" <> resposta <> "\")"
    IrPara(destino) -> "m6(\"" <> destino <> "\")"
    PedirDica(n) -> "m7(" <> int.to_string(n) <> ")"
    Sair -> "exit()"
  }
}

/// Executa a opção, imprime o comando e a mensagem no terminal e devolve
/// o novo estado (camada de apresentação).
pub fn mostrar(estado: Jogo, opcao: MainMenu) -> Jogo {
  let #(novo, mensagem) = executar(estado, opcao)
  io.println("\n> " <> descrever_opcao(opcao))
  io.println(mensagem)
  novo
}

/// Executa e imprime uma lista de opções em sequência (recursão em
/// cauda) e devolve o estado final.
pub fn mostrar_roteiro(estado: Jogo, opcoes: List(MainMenu)) -> Jogo {
  case opcoes {
    [] -> estado
    [opcao, ..resto] -> mostrar_roteiro(mostrar(estado, opcao), resto)
  }
}

/// Roteiro de uma partida completa, da Recepção até a fuga. Inclui uma
/// resposta errada (custa 10 pontos de vida) e a leitura de pistas.
pub fn roteiro_fuga() -> List(MainMenu) {
  [
    m1(),
    m4("Nota Adesiva"),
    m4("Rainha de Ouros"),
    m3(),
    m7(1),
    m5("ABCD"),
    m5("MAIN"),
    m6("Auditoria"),
    m4("Manual de Protocolo"),
    m4("Trilha de Auditoria"),
    m4("Rei de Copas"),
    m4("Valete de Espadas"),
    m5("RAFAEL 02, THIAGO 03, FERNANDA 04"),
    m6("Servidores"),
    m4("Ás de Paus"),
    m4("Placa de Bronze"),
    m5("RAINHA REI VALETE AS"),
    m2(),
    m6("Saída"),
  ]
}

/// Testes das funções m1..m7 e exit.
pub fn menus_examples() {
  check.eq(m1(), Explorar)
  check.eq(m2(), Inventario)
  check.eq(m3(), Enigmas)
  check.eq(m4("Nota Adesiva"), Interagir("Nota Adesiva"))
  check.eq(m5("MAIN"), Resolver("MAIN"))
  check.eq(m6("Auditoria"), IrPara("Auditoria"))
  check.eq(m7(2), PedirDica(2))
  check.eq(exit(), Sair)
}

/// Testes de `descrever_opcao`.
pub fn descrever_opcao_examples() {
  check.eq(descrever_opcao(m1()), "m1()")
  check.eq(descrever_opcao(m4("Rei de Copas")), "m4(\"Rei de Copas\")")
  check.eq(descrever_opcao(m7(3)), "m7(3)")
  check.eq(descrever_opcao(exit()), "exit()")
}

/// Testes de `executar` (cada variante do menu, a transição de estado e
/// o estado anterior preservado).
pub fn executar_examples() {
  let j0 = jogo.novo_jogo("Ana")
  check.eq(string.contains(executar(j0, m1()).1, "Nota Adesiva"), True)
  check.eq(executar(j0, m2()).1, "Inventário vazio.\nPontos de vida: 100")
  check.eq(string.contains(executar(j0, m3()).1, "Enigma:"), True)
  check.eq(string.contains(executar(j0, m7(2)).1, "Pista 2:"), True)
  check.eq(executar(j0, exit()).1, "Simulação encerrada.")
  let j1 = executar(j0, m4("Rainha de Ouros")).0
  check.eq(j1.jogador.inventario, ["Rainha de Ouros"])
  check.eq(j0.jogador.inventario, [])
  check.eq(executar(j0, m5("ABCD")).0.jogador.pontos_de_vida, 90)
  check.eq(
    executar(j0, m6("Auditoria")).1,
    "Acesso negado: é necessário possuir \"Cartão de Acesso Nível 1\".",
  )
}

/// Teste da partida completa: a fuga com todos os itens e 90 pontos de
/// vida, e o bloqueio de ações depois do fim.
pub fn roteiro_fuga_examples() {
  let fim = executar_roteiro(jogo.novo_jogo("Ana"), roteiro_fuga())
  check.eq(jogo.situacao(fim), Fugiu)
  check.eq(jogo.bloqueio_ativo(fim), False)
  check.eq(fim.jogador.pontos_de_vida, 90)
  check.eq(jogador.contar_itens(fim.jogador.inventario), 8)
  check.eq(fim.jogador.inventario, [
    "Nota Adesiva",
    "Rainha de Ouros",
    "Cartão de Acesso Nível 1",
    "Rei de Copas",
    "Valete de Espadas",
    "Cartão de Acesso Nível 2",
    "Ás de Paus",
    "Registro Autêntico (Dados Recuperados)",
  ])
  check.eq(
    executar(fim, m1()).1,
    "A simulação já terminou. Você escapou do laboratório levando os registros autênticos!",
  )
  check.eq(executar(fim, exit()).1, "Simulação encerrada.")
}
