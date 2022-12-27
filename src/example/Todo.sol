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
        string memory todosString = "[";
        for (uint256 i = 0; i < todos.length; i += 1) {
            Todo storage todo = todos[i];
            todosString = todosString.concat(
                "{",
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
        todosString = todosString.concat("]");
        return json(todosString);
    }

    function getIndex(HttpMessages.Request calldata request)
        external
        view
        override
        returns (HttpMessages.Response memory)
    {
        return
            html(
                H.html5(
                    StringConcat.concat(
                        H.head(
                            StringConcat.concat(
                                H.title("fallback todos"),
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
                                "class='mx-auto py-5' style='max-width: 500px'",
                                StringConcat.concat(
                                    H.h1("fallback() Todo App"),
                                    H.a(
                                        "href='https://github.com/nathanhleung/fallback'",
                                        "GitHub"
                                    ),
                                    H.form(
                                        "class='py-5'",
                                        StringConcat.concat(
                                            H.h4("Create New"),
                                            H.label(
                                                "What do you want to get done?"
                                            ),
                                            H.br(),
                                            H.div(
                                                "class='my-2'",
                                                StringConcat.concat(
                                                    H.input(
                                                        "type='text' class='form-control' name='new-todo' required pattern='[a-zA-Z0-9]+' placeholder='Learn Solidity'"
                                                    ),
                                                    H.small(
                                                        "Alphanumeric only, please"
                                                    )
                                                )
                                            ),
                                            H.button(
                                                "class='my-2 btn btn-primary' type='submit'",
                                                "Submit"
                                            )
                                        )
                                    ),
                                    H.div(
                                        "class='py-5'",
                                        StringConcat.concat(
                                            H.h4("Todos"),
                                            H.ul(
                                                "id='todos' class='list-group'",
                                                "(todos loading...)"
                                            )
                                        )
                                    ),
                                    H.script(
                                        "document.addEventListener('DOMContentLoaded', (e) => {"
                                        "  function displayTodos(todosJson) {"
                                        "    const todosElement = document.getElementById('todos');"
                                        "    todosElement.innerHTML = todosJson.map(todo =>"
                                        "      `<li class='list-group-item d-flex justify-content-between align-items-center'>"
                                        "        <span>"
                                        "          ${DOMPurify.sanitize(todo.content)}"
                                        "        </span>"
                                        "        ${todo.completed"
                                        "          ? `<span class='badge bg-success rounded-pill'>Completed</span>`"
                                        "          : `<a onclick='completeTodo(${todo.id})' href='#'>Mark Complete</a>`}"
                                        "      </li>`"
                                        "    ).join('') || '(no todos yet)';"
                                        "  }"
                                        ""
                                        "  fetch('/todos')"
                                        "    .then(res => res.json())"
                                        "    .then(displayTodos);"
                                        ""
                                        "  const form = document.querySelector('form');"
                                        "  form.addEventListener('submit', (e) => {"
                                        "    e.preventDefault();"
                                        "    const newTodo = e.target[0].value;"
                                        "    fetch('/new-todo', {"
                                        "      method: 'POST',"
                                        "      headers: {"
                                        "        'Content-Type': 'text/plain',"
                                        "      },"
                                        "      body: newTodo,"
                                        "    }).then(res => res.json())"
                                        "      .then(displayTodos)"
                                        "      .catch(console.error);"
                                        "  });"
                                        "});"
                                        ""
                                        "function completeTodo(id) {"
                                        "  console.log(id);"
                                        "}"
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function getTodos(HttpMessages.Request calldata request)
        external
        view
        returns (HttpMessages.Response memory)
    {
        return jsonTodos();
    }

    function postNewTodo(HttpMessages.Request calldata request)
        external
        returns (HttpMessages.Response memory)
    {
        string memory contentString = string(request.content);

        if (!contentString.isAlphanumeric()) {
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
