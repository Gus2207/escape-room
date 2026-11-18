import gleam/io
import gleam/string
import in
import jogo.{type Jogo}
import menus.{type MainMenu}
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

/// Inicia o jogo na Recepção: imprime a introdução, o menu de comandos
/// e a descrição da sala inicial, aguardando as ações no terminal.
pub fn main() -> Nil {
  io.println(introducao())
  menus.display_main_menu()
  let estado = jogo.novo_jogo("Pesquisador(a)")
  let interacao = terminal(estado)
  interacao
  Nil
}

/// Cria um novo jogo com o jogador na Recepção.
pub fn novo_jogo(nome: String) -> Jogo {
  jogo.novo_jogo(nome)
}

/// Executa uma opção do menu sobre `estado`, imprime o resultado e
/// devolve o novo estado.
//pub fn mostrar(estado: Jogo, opcao: MainMenu) -> Jogo {
 // menus.mostrar(estado, opcao)
  //}

pub fn terminal(estado: Jogo) -> #(Jogo, String) {
  let usuario = in.read_line()
  case usuario {
    Ok(texto) ->
      case texto {
        "m1()\n" -> conecta_terminal_executar(estado, m1())
        "m2()\n" -> conecta_terminal_executar(estado, m2())
        "m3()\n" -> conecta_terminal_executar(estado, m3())
        "m4()\n" -> {
          case in.read_line() {
            Ok(arg) -> conecta_terminal_executar(estado, m4(string.trim(arg)))
            Error(_) -> terminal(estado)
          }
        }
        "m5()\n" -> {
          case in.read_line() {
            Ok(arg) -> conecta_terminal_executar(estado, m5(string.trim(arg)))
            Error(_) -> terminal(estado)
          }
        }
        "m6()\n" -> {
          case in.read_line() {
            Ok(arg) -> conecta_terminal_executar(estado, m6(string.trim(arg)))
            Error(_) -> terminal(estado)
          }
        }
        "exit()\n" -> conecta_terminal_executar(estado, exit())
        _ -> {
          io.println("Opção inválida.")
          terminal(estado)
        }
      }
    _ -> {
      io.println("Erro na leitura.")
      terminal(estado)
    }
  }
}

pub fn conecta_terminal_executar(
  estado: Jogo,
  opcao: MainMenu,
) -> #(Jogo, String) {
  let #(novo_estado, mensagem) = menus.executar(estado, opcao)
  io.println(mensagem)
  case jogo.situacao(novo_estado){
    jogo.EmAndamento -> {
      menus.display_main_menu()
      terminal(novo_estado)
    }
    jogo.Fugiu -> {
      #(novo_estado, mensagem)
    }
    }
  }



/// Opção "Explorar ambiente".
pub fn m1() -> MainMenu {
  menus.m1()
}

/// Opção "Consultar inventário".
pub fn m2() -> MainMenu {
  menus.m2()
}

/// Opção "Examinar enigmas".
pub fn m3() -> MainMenu {
  menus.m3()
}

/// Opção "Interagir com o objeto `nome_objeto`".
pub fn m4(nome_objeto: String) -> MainMenu {
  menus.m4(nome_objeto)
}

/// Opção "Resolver o enigma da sala com `resposta`".
pub fn m5(resposta: String) -> MainMenu {
  menus.m5(resposta)
}

/// Opção "Ir para `destino`".
pub fn m6(destino: String) -> MainMenu {
  menus.m6(destino)
}

/// Opção "Encerrar simulação".
pub fn exit() -> MainMenu {
  menus.exit()
}

/// Testes de `introducao`.
pub fn introducao_examples() {
  check.eq(
    string.starts_with(introducao(), "=== A SALA DOS DADOS VAZADOS"),
    True,
  )
  check.eq(string.contains(introducao(), "3 salas"), True)
}
