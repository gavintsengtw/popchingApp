package com.popching.cams.repository;

import com.popching.cams.entity.FixbaseHis;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FixbaseHisRepository extends JpaRepository<FixbaseHis, String> {
}
