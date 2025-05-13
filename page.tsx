"use client";

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
      <h1 style={{ fontSize: "1.5rem", fontWeight: "bold", textAlign: "center" }}>Reserva de Lavanderia</h1>
      <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
        <input name="apartment" value={form.apartment} onChange={handleChange} placeholder="Apartamento" />
        <input name="phone" type="tel" value={form.phone} onChange={handleChange} placeholder="Telefone (WhatsApp)" />
        <input type="datetime-local" name="datetime" value={form.datetime} onChange={handleChange} />
        <div style={{ display: "flex", flexWrap: "wrap", gap: "0.5rem" }}>
          {[...washers, ...dryers].map((m) => (
            <button key={m} type="button" onClick={() => setForm({ ...form, machine: m })} style={{
              padding: "0.5rem",
              border: form.machine === m ? "2px solid black" : "1px solid gray",
              borderRadius: "4px"
            }}>
              {m}
            </button>
          ))}
        </div>
        <button type="submit" style={{ padding: "0.75rem", backgroundColor: "#000", color: "#fff" }}>Reservar</button>
      </form>

      <div style={{ marginTop: "2rem" }}>
        <h2 style={{ fontSize: "1.25rem", fontWeight: "bold" }}>Reservas Realizadas</h2>
        {reservations.length === 0 && <p>Nenhuma reserva ainda.</p>}
        <ul style={{ listStyle: "none", padding: 0 }}>
          {reservations.map((r, idx) => (
            <li key={idx} style={{ border: "1px solid #ccc", padding: "0.75rem", marginTop: "0.5rem" }}>
              <p><strong>Apartamento:</strong> {r.apartment}</p>
              <p><strong>Máquina:</strong> {r.machine}</p>
              <p><strong>Data e Hora:</strong> {format(new Date(r.datetime), 'dd/MM/yyyy HH:mm')}</p>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}