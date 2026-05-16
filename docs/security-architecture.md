# Security Architecture

This document describes how network isolation, security groups, and load balancer routing work together to protect the Expense Tracker 3-tier deployment on AWS.

---

## Table of Contents

1. [Design Principles](#design-principles)
2. [Traffic Flow](#traffic-flow)
3. [Subnet Isolation](#subnet-isolation)
4. [Security Group Communication Matrix](#security-group-communication-matrix)
5. [ALB Routing and Exposure](#alb-routing-and-exposure)
6. [Internal vs External Communication](#internal-vs-external-communication)
7. [Database Protection](#database-protection)
8. [Application-Layer Controls](#application-layer-controls)
9. [Threat Model Summary](#threat-model-summary)

---

## Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Least privilege** | Security groups allow only required ports between known sources |
| **Defense in depth** | VPC segmentation + SGs + private RDS + no public backend IPs |
| **Single entry point** | All user traffic enters through External ALB only |
| **No direct DB access** | RDS has no public IP; only backend SG can reach port 3306 |
| **Secrets not in images** | RDS credentials injected at runtime via EC2 user data / Parameter Store |

---

## Traffic Flow

### End-User Request (Browser → Application)

```
┌──────────┐     HTTPS/HTTP      ┌─────────────────┐
│  Browser │ ──────────────────► │  External ALB   │
│ (User)   │                     │  (Public subnet)│
└──────────┘                     └────────┬────────┘
                                          │
                    ┌─────────────────────┼
                    │ Path: /*            │ Path: /api/*        
                    ▼                     ▼                     
         ┌──────────────────┐   ┌──────────────────┐         
         │ Frontend EC2     │   │ Backend EC2      │         
         │ nginx :80        │   │ Express :4000    │         
         │ (Public subnet)  │   │ (Private subnet) │         
         └──────────────────┘   └────────┬─────────┘         
                                         │ MySQL :3306       
                                         ▼                   
                                  ┌──────────────────┐         
                                  │ Amazon RDS       │         
                                  │ (Private DB)     │         
                                  └──────────────────┘         
```

### Step-by-Step

1. **User** opens the External ALB DNS name in a browser.
2. **ALB** evaluates listener rules:
   - Static assets and SPA routes (`/*`) → Frontend target group (port 80).
   - API calls (`/api/*`) → Backend target group (port 4000).
3. **Frontend container** serves pre-built React static files via nginx. No database access.
4. **Browser JavaScript** calls `VITE_API_URL + /api/...` — same ALB origin when path-based routing is used.
5. **Backend container** validates the request, queries RDS over private network, returns JSON.
6. **RDS** responds only to connections from backend security group members.

---

## Subnet Isolation

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        VPC 10.0.0.0/16                                  │
│                                                                         │
│  ┌──────────────────────────── PUBLIC SUBNETS ────────────────────────┐ │
│  │  Internet Gateway ◄──► ALB, Frontend EC2, NAT Gateway              │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────────────── PRIVATE APP SUBNETS ───────────────────┐ │
│  │  Backend EC2 ASG (no public IP)                                      │ │
│  │  Outbound via NAT Gateway only (Docker Hub, patches)                 │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────────────── PRIVATE DB SUBNETS ────────────────────┐ │
│  │  RDS MySQL only — no IGW route, no NAT route                         │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

| Subnet Tier | Internet Inbound | Internet Outbound | Workloads |
|-------------|------------------|-------------------|-----------|
| **Public** | Yes (via IGW) | Yes (via IGW) | ALB, frontend EC2, NAT |
| **Private App** | No | Yes (via NAT only) | Backend EC2 |
| **Private DB** | No | No | RDS |

**Why this matters:** Even if an attacker discovers a backend private IP, they cannot reach it directly from the internet. Traffic must pass through the ALB, which enforces listener rules and can later be protected with WAF.

---

## Security Group Communication Matrix

| Source | Destination | Port | Allowed | Purpose |
|--------|-------------|------|---------|---------|
| Internet (`0.0.0.0/0`) | `sg-alb-external` | 80, 443 | ✅ | User traffic |
| `sg-alb-external` | `sg-frontend-ec2` | 80 | ✅ | Serve React app |
| `sg-alb-external` | `sg-backend-ec2` | 4000 | ✅ | API path routing |
| `sg-backend-ec2` | `sg-rds` | 3306 | ✅ | Database queries |
| `sg-frontend-ec2` | `sg-backend-ec2` | 4000 | ❌ | Not required — browser uses ALB |
| Internet | `sg-backend-ec2` | any | ❌ | Backend has no public IP |
| Internet | `sg-rds` | 3306 | ❌ | RDS not publicly accessible |
| `sg-frontend-ec2` | `sg-rds` | 3306 | ❌ | Frontend never touches DB |

### Visual SG Flow

```
Internet
   │
   ▼
[sg-alb-external]
   │
   ├──────────────► [sg-frontend-ec2] :80
   │
   └──────────────► [sg-backend-ec2] :4000
                           │
                           ▼
                    [sg-rds] :3306
```

---

## ALB Routing and Exposure

The External ALB is the **only** internet-facing application endpoint.

| Path | Target | Exposure |
|------|--------|----------|
| `/*` | Frontend nginx | Public — static UI only |
| `/api/*` | Express API | Public — application logic |
| `/health` | Backend (optional rule) | Public — health probe |

### Security Considerations

- **Health endpoints** are reachable publicly when routed through ALB. They expose minimal information (`ok` or `{ status: "ok" }`). Restrict further with WAF if needed.
- **No internal ALB required** for browser clients when path-based routing on the External ALB forwards `/api/*` to private backend instances. ALB can target private subnet instances without public IPs.
- **HTTPS** should be enabled in production (ACM certificate) to encrypt traffic in transit.

---

## Internal vs External Communication

| Communication Path | Type | Details |
|---------------------|------|---------|
| Browser → ALB | External | Public internet |
| ALB → Frontend EC2 | Internal (VPC) | Stays within AWS network |
| ALB → Backend EC2 | Internal (VPC) | Backend in private subnet; ALB initiates connection |
| Backend EC2 → RDS | Internal (VPC) | Private DNS endpoint resolves to private IP |
| Backend EC2 → Docker Hub | External (egress) | Via NAT Gateway in public subnet |
| Frontend EC2 → Docker Hub | External (egress) | Via Internet Gateway (public subnet) |
| RDS → Internet | None | Fully isolated |

### Why the Frontend Does Not Call the Backend Directly

The React app runs in the **user's browser**, not on the frontend EC2 instance. API calls go from the browser to the ALB — never from frontend EC2 to backend EC2. This is why:

- `sg-frontend-ec2` does not need access to `sg-backend-ec2`
- `VITE_API_URL` must point to the ALB (browser-reachable), not a private backend IP

---

## Database Protection

| Control | Status |
|---------|--------|
| Deployed in private DB subnets | ✅ |
| Publicly accessible = No | ✅ |
| Security group limits source to backend SG | ✅ |
| Credentials via environment variables (not in Git) | ✅ |
| Encryption at rest (RDS option) | ✅ Recommended |
| Encryption in transit (SSL to MySQL) | Optional — enable for production |
| Automated backups | ✅ Recommended |

### Credential Handling

```
❌  Hardcoded in Dockerfile or Git
✅  EC2 user data from Parameter Store / Secrets Manager
✅  backend/.env locally (gitignored) for development only
```

---

## Application-Layer Controls

| Control | Location | Description |
|---------|----------|-------------|
| **CORS** | `backend/server.js` | Restricts API origins via `CORS_ORIGINS` |
| **Input validation** | `backend/server.js` | Required fields and `income`/`expense` enum check |
| **Non-root container** | `backend/Dockerfile` | Process runs as `node` user |
| **No localhost DB defaults** | `backend/db.js` | Fails fast if RDS env vars missing |
| **Build-time API URL** | `frontend/Dockerfile` | `VITE_API_URL` baked at build — no runtime secret exposure |

---

## Threat Model Summary

| Threat | Mitigation |
|--------|------------|
| Direct internet attack on backend | Private subnet, no public IP |
| Direct internet attack on database | Private DB subnet, SG restricted |
| Unauthorized API access | ALB as choke point; add WAF + auth in future |
| Credential leak via image | Env vars at runtime, not in Docker layers |
| Lateral movement from frontend EC2 | Frontend has no path to RDS or backend SG |
| DDoS | AWS Shield Standard on ALB; WAF rate limiting (future) |

---

## Related Documentation

- [aws-setup.md](aws-setup.md) — Step-by-step deployment
- [troubleshooting.md](troubleshooting.md) — Connectivity debugging
- [../README.md](../README.md) — Project overview
