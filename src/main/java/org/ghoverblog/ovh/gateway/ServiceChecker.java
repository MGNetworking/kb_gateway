package org.ghoverblog.ovh.gateway;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.discovery.ReactiveDiscoveryClient;
import org.springframework.stereotype.Component;

@Component
public class ServiceChecker {

    @Autowired
    private ReactiveDiscoveryClient discoveryClient;

    @PostConstruct
    public void printServices() {
        discoveryClient.getServices()
                .collectList()
                .subscribe(services -> System.out.println("Services Kubernetes : " + services));
    }
}
