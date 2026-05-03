import { Switch, Route, Router as WouterRouter } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import NotFound from "@/pages/not-found";
import { Layout } from "@/components/layout";
import Home from "@/pages/home";
import Puantaj from "@/pages/puantaj";
import Malzeme from "@/pages/malzeme";
import Sevkiyat from "@/pages/sevkiyat";
import SatinAlma from "@/pages/satin-alma";
import Imalat from "@/pages/imalat";
import Kantar from "@/pages/kantar";

const queryClient = new QueryClient();

function Router() {
  return (
    <Layout>
      <Switch>
        <Route path="/" component={Home} />
        <Route path="/puantaj" component={Puantaj} />
        <Route path="/malzeme" component={Malzeme} />
        <Route path="/sevkiyat" component={Sevkiyat} />
        <Route path="/satin-alma" component={SatinAlma} />
        <Route path="/imalat" component={Imalat} />
        <Route path="/kantar" component={Kantar} />
        <Route component={NotFound} />
      </Switch>
    </Layout>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, "")}>
          <Router />
        </WouterRouter>
        <Toaster />
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
