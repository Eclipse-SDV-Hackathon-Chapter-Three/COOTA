import './App.css'
import CampaignForm from './CampaignForm'

function App() {

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 16 }}>
        <img src='coota_logo.png' alt="COOTA Logo" style={{ height: 270 }} />
      </div>
      <h1>Campaign Launcher</h1>
      <CampaignForm />
    </>
  )
}

export default App
