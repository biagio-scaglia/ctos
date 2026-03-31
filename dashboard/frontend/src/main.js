import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import Dashboard from './views/Dashboard.vue'
import Processes from './views/Processes.vue'
import NetworkView from './views/NetworkView.vue'
import GuardianView from './views/GuardianView.vue'
import MahoragaView from './views/MahoragaView.vue'
import './style.css'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/',          component: Dashboard },
    { path: '/processes', component: Processes },
    { path: '/network',   component: NetworkView },
    { path: '/guardian',  component: GuardianView },
    { path: '/mahoraga',  component: MahoragaView },
  ],
})

createApp(App).use(router).mount('#app')
