// Script para crear eventos de prueba en el backend
// Ejecutar con: node create_test_events.js

const axios = require('axios');

const baseURL = 'http://localhost:3000/api';

// Eventos de prueba
const testEvents = [
  {
    name: 'Fiesta Neon Night',
    description: 'Una noche llena de luces neon y música electrónica',
    location: 'Club Central',
    schedule: new Date('2024-02-15T22:00:00Z').toISOString(),
    category: 'electronica',
    participants: []
  },
  {
    name: 'Concierto Rock Underground',
    description: 'Los mejores grupos de rock alternativo de la ciudad',
    location: 'Sala Underground',
    schedule: new Date('2024-02-20T21:00:00Z').toISOString(),
    category: 'rock',
    participants: []
  },
  {
    name: 'Hip Hop Session',
    description: 'Batalla de rap y freestyle con DJs locales',
    location: 'Centro Cultural',
    schedule: new Date('2024-02-18T20:30:00Z').toISOString(),
    category: 'hip-hop',
    participants: []
  },
  {
    name: 'Jazz & Blues Night',
    description: 'Una velada íntima con lo mejor del jazz y blues',
    location: 'Jazz Café',
    schedule: new Date('2024-02-22T19:00:00Z').toISOString(),
    category: 'jazz',
    participants: []
  },
  {
    name: 'Reggaeton Party',
    description: 'La mejor música latina para bailar toda la noche',
    location: 'Discoteca Tropical',
    schedule: new Date('2024-02-25T23:00:00Z').toISOString(),
    category: 'reggaeton',
    participants: []
  }
];

async function createEvents() {
  try {
    console.log('🎉 Creando eventos de prueba...\n');
    
    for (let i = 0; i < testEvents.length; i++) {
      const event = testEvents[i];
      console.log(`📅 Creando evento ${i + 1}/${testEvents.length}: ${event.name}`);
      
      try {
        const response = await axios.post(`${baseURL}/event`, event, {
          headers: {
            'Content-Type': 'application/json'
          }
        });
        
        console.log(`✅ Evento creado con ID: ${response.data.id || response.data._id}`);
      } catch (error) {
        console.log(`❌ Error creando evento: ${error.response?.data?.message || error.message}`);
      }
      
      console.log('---');
    }
    
    console.log('\n🎊 ¡Eventos de prueba creados exitosamente!');
    console.log('Ahora puedes verificar en tu app Flutter si aparecen los eventos.');
    
  } catch (error) {
    console.error('Error general:', error.message);
  }
}

// Verificar si el servidor está funcionando
async function checkServer() {
  try {
    console.log('🔍 Verificando servidor...');
    const response = await axios.get(`${baseURL}/event`);
    console.log(`✅ Servidor funcionando. Eventos actuales: ${response.data.length || 0}`);
    return true;
  } catch (error) {
    console.log(`❌ Error conectando al servidor: ${error.message}`);
    console.log('Asegúrate de que tu servidor Node.js esté ejecutándose en http://localhost:3000');
    return false;
  }
}

async function main() {
  console.log('🚀 Script de creación de eventos de prueba\n');
  
  const serverOk = await checkServer();
  if (serverOk) {
    await createEvents();
  }
}

main();