import { useState } from "react";
import { format } from "date-fns";

export default function LaundryApp() {
  const washers = ["Lavadora 1", "Lavadora 2", "Lavadora 3"];
  const dryers = ["Secadora 1", "Secadora 2", "Secadora 3"];

  const [form, setForm] = useState({
    apartment: "",
    datetime: "",
    machine: "",
    phone: "",
  });
  const [reservations, setReservations] = useState([]);

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!form.apartment || !form.datetime || !form.machine || !form.phone) return;
    setReservations([...reservations, { ...form }]);

    const formattedDate = format(new Date(form.datetime), 'dd/MM/yyyy HH:mm');
    const message = encodeURIComponent(
      `Olá! Sua reserva foi confirmada:\nMáquina: ${form.machine}\nApartamento: ${form.apartment}\nData/Hora: ${formattedDate}`
    );
    const phoneNumber = form.phone.replace(/\D/g, "");
    window.open(`https://wa.me/55${phoneNumber}?text=${message}`, '_blank');

    setForm({ apartment: "", datetime: "", machine: "", phone: "" });
  };

  return (
    <div style={{ maxWidth: "600px", margin: "0 auto", padding: "1rem" }}>
      <h1 style={{ textAlign: "center" }}>Reserva de Lavanderia</h1>
      <form onSubmit={handleSubmit} style={{ display: "grid", gap: "1rem" }}>
        <input
          name="apartment"
          value={form.apartment}
          onChange={handleChange}
          placeholder="Apartamento"
        />
        <input
          name="phone"
          type="tel"
          value={form.phone}
          onChange={handleChange}
          placeholder="Telefone (WhatsApp)"
        />
        <input
          type="datetime-local"
          name="datetime"
          value={form.datetime}
          onChange={handleChange}
        />
        <div style={{ display: "flex", flexWrap: "wrap", gap: "0.5rem" }}>
          {[...washers, ...dryers].map((m) => (
            <button
              key={m}
              type="button"
              style={{
                background: form.machine === m ? "#007bff" : "#e0e0e0",
                color: form.machine === m ? "#fff" : "#000",
                border: "none",
                padding: "0.5rem 1rem",
                cursor: "pointer"
              }}
              onClick={() => setForm({ ...form, machine: m })}
            >
              {m}
            </button>
          ))}
        </div>
        <button type="submit" style={{ padding: "0.75rem", background: "#28a745", color: "#fff", border: "none" }}>
          Reservar
        </button>
      </form>

      <div style={{ marginTop: "2rem" }}>
        <h2>Reservas Realizadas</h2>
        {reservations.length === 0 ? (
          <p>Nenhuma reserva ainda.</p>
        ) : (
          reservations.map((r, idx) => (
            <div key={idx} style={{ padding: "0.5rem", border: "1px solid #ccc", marginTop: "0.5rem" }}>
              <p><strong>Apartamento:</strong> {r.apartment}</p>
              <p><strong>Máquina:</strong> {r.machine}</p>
              <p><strong>Data e Hora:</strong> {format(new Date(r.datetime), 'dd/MM/yyyy HH:mm')}</p>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
