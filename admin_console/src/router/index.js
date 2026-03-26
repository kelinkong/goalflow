import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Dashboard from '../views/Dashboard.vue'
import Users from '../views/Users.vue'
import Logs from '../views/Logs.vue'
import Templates from '../views/Templates.vue'
import TemplateCreate from '../views/TemplateCreate.vue'

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', name: 'Login', component: Login },
  { path: '/users', name: 'Users', component: Users },
  { path: '/dashboard', name: 'Dashboard', component: Dashboard },
  { path: '/templates', name: 'Templates', component: Templates },
  { path: '/templates/create', name: 'TemplateCreate', component: TemplateCreate },
  { path: '/logs', name: 'Logs', component: Logs }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫，需要登录
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  if (to.path !== '/login' && !token) {
    next('/login')
  } else {
    next()
  }
})

export default router
