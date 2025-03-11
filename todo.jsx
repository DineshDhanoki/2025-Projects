import React, { useState } from 'react';

export default function App() {
    const [todos, setTodos] = useState([]);
    const [input, setInput] = useState("");
    const [editID, setEditID] = useState(null);

    const handleSubmit = () => {
        if (editID !== null) {
            setTodos((todos) =>
                todos.map((todo) =>
                    todo.id === editID ? { ...todo, text: input } : todo
                )
            );
            setEditID(null);
        } else {
            setTodos((todos) => [
                ...todos,
                { text: input, id: Math.floor(Math.random() * 100) },
            ]);
        }
        setInput("");
    };

    const removeTodos = (id) => {
        setTodos((todos) => todos.filter((t) => t.id !== id));
    };

    const editTodos = (id) => {
        const todoEdit = todos.find((todo) => todo.id === id);
        if (todoEdit) {
            setInput(todoEdit.text);
            setEditID(id);
        }
    };

    return (
        <div>
            <input
                type="text"
                placeholder="Enter a todo"
                value={input}
                onChange={(e) => setInput(e.target.value)}
            />
            <button onClick={handleSubmit}>
                {editID !== null ? "Update" : "Submit"}
            </button>
            <ul>
                {todos.map(({ text, id }) => (
                    <li key={id}>
                        <span>{text}</span>
                        <button onClick={() => editTodos(id)}>Edit</button>
                        <button onClick={() => removeTodos(id)}>Remove</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}