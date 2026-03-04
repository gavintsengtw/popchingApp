package com.popching.cams.repository;

import com.popching.cams.entity.SystemFunction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SystemFunctionRepository extends JpaRepository<SystemFunction, String> {
    Optional<SystemFunction> findByFuncId(String funcId);

    List<SystemFunction> findByFuncIdIn(List<String> funcIds);
}
