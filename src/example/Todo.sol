// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {H} from "../html-dsl/H.sol";
import {HttpConstants} from "../http/HttpConstants.sol";
import {HttpMessages} from "../http/HttpMessages.sol";
import {DefaultServer} from "../HttpServer.sol";
import {StringConcat} from "../strings/StringConcat.sol";
import {StringCompare} from "../strings/StringCompare.sol";
import {WebApp} from "../WebApp.sol";

/**
 * Example todo web app. Add routes here.
 */
contract TodoApp is WebApp {
    using Strings for uint256;
    using StringConcat for string;
    using StringCompare for string;

    struct Todo {
        uint256 id;
        bool completed;
        string content;
    }
    Todo[] private todos;
    uint256 todosCount;

    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/todos"] = "getTodos";
        routes[HttpConstants.Method.POST]["/new-todo"] = "postNewTodo";
        routes[HttpConstants.Method.POST][
            "/completed-todo"
        ] = "postCompletedTodo";
    }

    function jsonTodos() private view returns (HttpMessages.Response memory) {
        string[] memory todoObjects = new string[](todos.length);
        for (uint256 i = 0; i < todos.length; i += 1) {
            Todo storage todo = todos[i];
            todoObjects[i] = StringConcat.concat(
                "{"
                '"id":',
                todo.id.toString(),
                ","
                '"completed":',
                todo.completed ? "true" : "false",
                ","
                '"content":"',
                todo.content,
                '"}'
            );
        }
        string memory todosString = StringConcat.concat(
            "[",
            StringConcat.join(todoObjects),
            "]"
        );
        return json(todosString);
    }

    function getIndex(HttpMessages.Request calldata request)
        external
        view
        override
        returns (HttpMessages.Response memory)
    {
        request;
        return
            html(
                H.html5(
                    StringConcat.concat(
                        H.head(
                            StringConcat.concat(
                                H.title("fallback() todos"),
                                H.link(
                                    'rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css" integrity="sha384-rbsA2VBKQhggwzxH7pPCaAqO46MgnOM80zW1RWuH61DGLwZJEdK2Kadq2F9CUG65" crossorigin="anonymous"'
                                ),
                                H.script(
                                    'src="https://cdnjs.cloudflare.com/ajax/libs/dompurify/2.4.1/purify.min.js" integrity="sha512-uHOKtSfJWScGmyyFr2O2+efpDx2nhwHU2v7MVeptzZoiC7bdF6Ny/CmZhN2AwIK1oCFiVQQ5DA/L9FSzyPNu6Q==" crossorigin="anonymous" referrerpolicy="no-referrer"',
                                    ""
                                )
                            )
                        ),
                        H.body(
                            H.main(
                                "class='mx-auto px-3 py-5' style='max-width: 500px'",
                                StringConcat.concat(
                                    H.h1("fallback() Demo Todo App"),
                                    H.p(
                                        StringConcat.concat(
                                            "Write web apps in Solidity &mdash; ",
                                            H.b("fallback()"),
                                            " is a Solidity web framework / a proof-of-concept implementation of HTTP over Ethereum."
                                        )
                                    ),
                                    H.p(
                                        StringConcat.concat(
                                            H.a(
                                                "href='https://github.com/nathanhleung/fallback'",
                                                "GitHub"
                                            ),
                                            H.span("&nbsp;&middot;&nbsp;"),
                                            H.a(
                                                "href='https://fallback.natecation.xyz'",
                                                "Docs"
                                            )
                                        )
                                    ),
                                    H.div(
                                        "class='py-4'",
                                        StringConcat.concat(
                                            H.small(
                                                "class='d-block'",
                                                StringConcat.concat(
                                                    "This todo app is deployed at ",
                                                    H.b(
                                                        Strings.toHexString(
                                                            uint160(
                                                                serverAddress
                                                            )
                                                        )
                                                    ),
                                                    " from ",
                                                    H.b(
                                                        H.a(
                                                            "href='https://github.com/nathanhleung/fallback/blob/main/src/example/Todo.sol'",
                                                            "Todo.sol"
                                                        )
                                                    )
                                                )
                                            ),
                                            H.small(
                                                "class='d-block mt-3'",
                                                StringConcat.concat(
                                                    "Transactions are being sent from ",
                                                    H.b(
                                                        uint256(
                                                            uint160(tx.origin)
                                                        ).toHexString(20)
                                                    ),
                                                    "."
                                                )
                                            )
                                        )
                                    ),
                                    H.form(
                                        "class='py-4'",
                                        StringConcat.concat(
                                            H.h4("Create New Todo"),
                                            H.label(
                                                "What do you want to get done?"
                                            ),
                                            H.br(),
                                            H.div(
                                                "class='my-2'",
                                                StringConcat.concat(
                                                    H.input(
                                                        "type='text' class='form-control' name='new-todo' required pattern='[a-zA-Z0-9 ]+' placeholder='Learn Solidity'"
                                                    ),
                                                    H.small(
                                                        "class='d-block mt-1'",
                                                        "Alphanumeric or spaces only, please."
                                                    )
                                                )
                                            ),
                                            H.button(
                                                "class='mt-2 btn btn-lg btn-primary' type='submit'",
                                                "Create Todo"
                                            ),
                                            H.br(),
                                            H.small(
                                                "class='d-block mt-1 text-muted'",
                                                "Request errors will be logged to the console."
                                            )
                                        )
                                    ),
                                    H.div(
                                        "class='py-5'",
                                        StringConcat.concat(
                                            H.div(
                                                "class='d-flex align-items-center mb-2 me-2'",
                                                StringConcat.concat(
                                                    H.h4(
                                                        "class='mb-0 me-4'",
                                                        "My Todos"
                                                    ),
                                                    H.button(
                                                        "onclick='toggleHideCompleted()' id='toggle-hide-completed' class='btn btn-sm btn-secondary'",
                                                        "Hide Completed"
                                                    )
                                                )
                                            ),
                                            H.ul(
                                                "id='todos' class='list-group'",
                                                "(todos loading...)"
                                            )
                                        )
                                    ),
                                    H.script(
                                        "let hideCompleted = false;"
                                        "let cachedTodos = [];"
                                        ""
                                        "function fetchAndDisplayTodos(useCached = false) {"
                                        "  if (useCached && cachedTodos.length > 0) {"
                                        "    displayTodos(cachedTodos);"
                                        "    return;"
                                        "  }"
                                        ""
                                        "  fetch('/todos')"
                                        "    .then(res => res.json())"
                                        "    .then(json => {"
                                        "      cachedTodos = json;"
                                        "      return json;"
                                        "    })"
                                        "    .then(displayTodos);"
                                        "}"
                                        ""
                                        "document.addEventListener('DOMContentLoaded', (e) => {"
                                        "  fetchAndDisplayTodos();"
                                        ""
                                        "  const form = document.querySelector('form');"
                                        "  form.addEventListener('submit', (e) => {"
                                        "    e.preventDefault();"
                                        "    const input = e.target[0];"
                                        "    const newTodo = input.value;"
                                        "    const button = e.target[1];"
                                        "    button.disabled = true;"
                                        "    button.innerText = 'Creating...';"
                                        ""
                                        "    fetch('/new-todo', {"
                                        "      method: 'POST',"
                                        "      body: newTodo,"
                                        "    }).then(res => res.json())"
                                        "      .then(json => {"
                                        "        cachedTodos = json;"
                                        "        return json;"
                                        "      })"
                                        "      .then(displayTodos)"
                                        "      .catch(console.error)"
                                        "      .finally(() => {"
                                        "        input.value = '';"
                                        "        button.disabled = false;"
                                        "        button.innerText = 'Create Todo';"
                                        "      });"
                                        "  });"
                                        "});"
                                        ""
                                        "function displayTodos(todosJson) {"
                                        "  const todosElement = document.getElementById('todos');"
                                        "  if (!todosElement) return;"
                                        ""
                                        "  todosElement.innerHTML = todosJson"
                                        "    .filter(todo => hideCompleted ? !todo.completed : true)"
                                        "    .map(todo =>"
                                        "      `<li id='todo-${todo.id}' class='list-group-item d-flex justify-content-between align-items-center'>"
                                        "        <span class='${todo.completed ? 'text-muted' : ''}'>"
                                        "          ${DOMPurify.sanitize(todo.content)}"
                                        "        </span>"
                                        "        ${todo.completed"
                                        "          ? `<span class='badge bg-success rounded-pill'>Completed</span>`"
                                        "          : `<a class='btn btn-sm btn-link p-0' onclick='completeTodo(${todo.id})'>Mark Complete</a>`}"
                                        "      </li>`"
                                        "    ).join('') || '(no todos)';"
                                        "}"
                                        ""
                                        "function completeTodo(id) {"
                                        "  const markCompletedLink = document.querySelector(`#todo-${id} a`);"
                                        "  markCompletedLink.classList.add('disabled');"
                                        "  markCompletedLink.innerText = 'Completing...';"
                                        "  fetch('/completed-todo', {"
                                        "    method: 'POST',"
                                        "    body: id,"
                                        "  }).then(res => res.json())"
                                        "    .then(json => {"
                                        "      cachedTodos = json;"
                                        "      return json;"
                                        "    })"
                                        "    .then(displayTodos)"
                                        "    .catch(console.error)"
                                        "    .finally(() => {"
                                        "      markCompletedLink.classList.remove('disabled');"
                                        "      markCompletedLink.innerText = 'Mark Complete';"
                                        "    });"
                                        "}"
                                        ""
                                        "function toggleHideCompleted() {"
                                        "  const button = document.getElementById('toggle-hide-completed');"
                                        "  hideCompleted = !hideCompleted;"
                                        "  button.innerText = hideCompleted ? 'Show Completed' : 'Hide Completed';"
                                        "  fetchAndDisplayTodos(true);"
                                        "}"
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function getTodos() external view returns (HttpMessages.Response memory) {
        return jsonTodos();
    }

    function postNewTodo(HttpMessages.Request calldata request)
        external
        returns (HttpMessages.Response memory)
    {
        string memory contentString = string(request.content);

        if (!contentString.isAlphanumericOrSpaces()) {
            return
                handleBadRequest(request, "Todo content must be alphanumeric.");
        }

        Todo memory newTodo;
        newTodo.id = todosCount;
        newTodo.completed = false;
        newTodo.content = contentString;

        todos.push(newTodo);
        todosCount += 1;

        return jsonTodos();
    }

    function postCompletedTodo(HttpMessages.Request calldata request)
        external
        returns (HttpMessages.Response memory)
    {
        for (uint256 i = 0; i < todos.length; i += 1) {
            Todo storage todo = todos[i];
            if (string(request.content).equals(todo.id.toString())) {
                todo.completed = true;
                break;
            }
        }
        return jsonTodos();
    }
}

contract TodoServer is DefaultServer {
    constructor() DefaultServer(new TodoApp()) {
        app.setDebug(true);
    }
}
