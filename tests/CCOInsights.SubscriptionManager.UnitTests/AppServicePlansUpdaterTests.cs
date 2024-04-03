﻿using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using CCOInsights.SubscriptionManager.Functions;
using CCOInsights.SubscriptionManager.Functions.Operations.AppServicePlans;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace CCOInsights.SubscriptionManager.UnitTests;

public class AppServicePlansUpdaterTests
{
    private readonly IAppServicePlansUpdater _updater;
    private readonly Mock<IStorage> _storageMock;
    private readonly Mock<ILogger<AppServicePlansUpdater>> _loggerMock;
    private readonly Mock<IAppServicePlansProvider> _providerMock;

    public AppServicePlansUpdaterTests()
    {
        _storageMock = new Mock<IStorage>();
        _loggerMock = new Mock<ILogger<AppServicePlansUpdater>>();
        _providerMock = new Mock<IAppServicePlansProvider>();
        _updater = new AppServicePlansUpdater(_storageMock.Object, _loggerMock.Object, _providerMock.Object);
    }

    [Fact]
    public async Task BlueprintArtifactUpdater_UpdateAsync_ShouldUpdate_IfValid()
    {
        var response = new AppServicePlansResponse { Id = "Id" };
        _providerMock.Setup(x => x.GetAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(new List<AppServicePlansResponse> { response });

        var subscriptionTest = new TestSubscription();
        await _updater.UpdateAsync(Guid.Empty.ToString(), subscriptionTest, CancellationToken.None);

        _providerMock.Verify(x => x.GetAsync(It.Is<string>(x => x == subscriptionTest.SubscriptionId), CancellationToken.None));
        _storageMock.Verify(x => x.UpdateItemAsync(It.IsAny<string>(), It.IsAny<string>(), It.Is<AppServicePlans>(x => x.SubscriptionId == subscriptionTest.SubscriptionId && x.TenantId == subscriptionTest.Inner.TenantId), It.IsAny<CancellationToken>()), Times.Once);
    }
}
