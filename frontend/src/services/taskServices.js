import axios from "axios";

// In K8s: REACT_APP_BACKEND_URL is set to /api/tasks at build time
// nginx inside the frontend pod proxies /api → backend:8080
const apiUrl = process.env.REACT_APP_BACKEND_URL || "/api/tasks";

export function getTasks() {
    return axios.get(apiUrl);
}

export function addTask(task) {
    return axios.post(apiUrl, task);
}

export function updateTask(id, task) {
    return axios.put(apiUrl + "/" + id, task);
}

export function deleteTask(id) {
    return axios.delete(apiUrl + "/" + id);
}