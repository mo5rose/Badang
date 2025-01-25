import React, { useState } from 'react';
import axios from 'axios';

function App() {
  const [status, setStatus] = useState(null);

  const checkHealth = async () => {
    try {
      // Adjust the endpoint according to your meterAPI URL within the local network
      const res = await axios.get('http://YOUR_METERAPI_HOST:8000/api/health/');
      setStatus(res.data);
    } catch (error) {
      console.error(error);
      setStatus({ error: 'Failed to connect to meterAPI' });
    }
  };

  return (
    <div className="p-4">
      <h1 className="text-2xl font-bold mb-4">Puteri Dashboard</h1>
      <button
        onClick={checkHealth}
        className="bg-blue-500 text-white px-4 py-2 rounded"
      >
        Check meterAPI Health
      </button>
      {status && (
        <div className="mt-4">
          <pre>{JSON.stringify(status, null, 2)}</pre>
        </div>
      )}
    </div>
  );
}

export default App;