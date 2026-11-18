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
/// - `Sair`: encerra a simulação.
pub type MainMenu {
  Explorar
  Inventario
  Enigmas
  Interagir(String)
  Resolver(String)
  IrPara(String)
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
  io.println("exit(): Encerrar simulação")
}

/// Opção "Explorar ambiente".
pub fn m1(estado: Jogo) -> #(Jogo, String) {
  executar(estado, Explorar)
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
    _, Sair -> #(estado, "Simulação encerrada.")
    _, _ -> #(estado, "A simulação já terminou. " <> jogo.mensagem_final(estado))
  }
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







