document.addEventListener("DOMContentLoaded", function () {
    const contenedor = document.getElementById("materias-container");
    const btnAgregar = document.getElementById("btn-agregar-materia");

    if (btnAgregar && contenedor) {
        btnAgregar.addEventListener("click", function () {
            const fila = contenedor.querySelector(".fila-materia");
            const nuevaFila = fila.cloneNode(true);
            nuevaFila.querySelectorAll("select, input").forEach((el) => (el.value = ""));
            contenedor.appendChild(nuevaFila);
        });

        contenedor.addEventListener("click", function (e) {
            if (e.target.classList.contains("btn-quitar-materia")) {
                const filas = contenedor.querySelectorAll(".fila-materia");
                if (filas.length > 1) {
                    e.target.closest(".fila-materia").remove();
                }
            }
        });
    }
});